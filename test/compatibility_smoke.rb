# Run against an already migrated development database:
# bundle exec rails runner plugins/redcase/test/compatibility_smoke.rb
# All records created by this script are rolled back.
require 'securerandom'
require 'nokogiri'
STDOUT.sync = true

raise 'Use the development or test database' unless Rails.env.development? || Rails.env.test?
ActionMailer::Base.perform_deliveries = false
checks = 0
check = lambda do |condition, description|
  raise "FAIL: #{description}" unless condition
  checks += 1
  puts "PASS: #{description}"
end

ActiveRecord::Base.transaction do
  suffix = SecureRandom.hex(5)
  password = SecureRandom.base64(24)
  user = User.new(login: "redcase-smoke-#{suffix}", firstname: 'Compatibility', lastname: 'Test',
                  mail: "#{suffix}@example.invalid", status: User::STATUS_ACTIVE, language: 'de')
  user.password = password
  user.password_confirmation = password
  user.save!
  role = Role.create!(name: "Redcase smoke #{suffix}", issues_visibility: 'default', permissions: [
    :view_issues, :add_issues, :edit_issues, :view_test_cases, :edit_test_cases, :execute_test_cases
  ])
  tracker = Tracker.find_by!(name: 'Test case')
  projects = 2.times.map do |i|
    project = Project.create!(name: "Redcase smoke #{i} #{suffix}", identifier: "redcase-smoke-#{i}-#{suffix}",
                               is_public: false)
    project.enabled_module_names = ['issue_tracking']
    project.trackers = [tracker, Tracker.find_by!(name: 'Bug')]
    project
  end
  project, foreign_project = projects
  Member.create!(project: project, user: user, roles: [role])
  User.current = user
  version = project.versions.create!(name: '6.1 smoke')
  environment = ExecutionEnvironment.get_default_for_project(project)
  foreign_environment = ExecutionEnvironment.get_default_for_project(foreign_project)
  root = TestSuite.get_root_for_project(project)
  foreign_root = TestSuite.get_root_for_project(foreign_project)
  suite = TestSuite.create!(name: 'Nested test suite', parent: root)
  execution = ExecutionSuite.get_root_for_project(project)
  foreign_execution = ExecutionSuite.get_root_for_project(foreign_project)
  child_execution = ExecutionSuite.create!(name: 'Nested execution', parent: execution)
  issue = Issue.create!(project: project, tracker: tracker, author: user, subject: "Test <tags> 'quoted'",
                        description: 'A reproducible test', status: IssueStatus.find_by!(name: 'In Progress'))
  test_case = TestCase.create!(issue: issue, test_suite: suite)
  child_execution.test_cases << test_case
  hidden_issue = Issue.create!(project: project, tracker: tracker, author: User.where(admin: true).first!,
                               subject: "Hidden private case #{suffix}", is_private: true)
  hidden_case = TestCase.create!(issue: hidden_issue, test_suite: suite)
  child_execution.test_cases << hidden_case
  foreign_issue = Issue.create!(project: foreign_project, tracker: tracker, author: user, subject: 'Foreign test')
  TestCase.create!(issue: foreign_issue, test_suite: foreign_root)
  check.call(root.persisted? && root.children.count == 3, 'root and nested suites persist')

  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.host! 'localhost'
  session.get '/login'
  token = Nokogiri::HTML(session.response.body).at_css('input[name="authenticity_token"]')&.[]('value')
  session.post '/login', params: {username: user.login, password: password, authenticity_token: token}
  check.call(session.response.redirect?, 'non-admin login')
  base = "/projects/#{project.id}/redcase"
  session.get base
  check.call(session.response.status == 200, 'Redcase page renders with a version')
  check.call(session.response.body.include?('Testfälle') && session.response.body.include?('Verwaltung') &&
             !session.response.body.include?('translation missing'), 'German page labels render without missing translations')
  token = Nokogiri::HTML(session.response.body).at_css('meta[name="csrf-token"]')&.[]('content')
  request = lambda do |method, path, params = {}, status = 200|
    session.public_send(method, "#{base}#{path}", params: params.merge(authenticity_token: token),
                        headers: {'Accept' => '*/*', 'X-Requested-With' => 'XMLHttpRequest'})
    check.call(session.response.status == status, "#{method.upcase} #{path}: #{status} (got #{session.response.status})")
    session.response
  end
  request.call(:get, '/testsuites')
  tree = JSON.parse(session.response.body)
  check.call(tree['text'] == 'Wurzel' && tree['children'].any? { |child| child['id'] == '.Unsorted' && child['text'] == 'Nicht zugeordnet' },
             'system suites translate labels while preserving identifiers')
  check.call(!session.response.body.include?(hidden_issue.subject), 'private cases are omitted from test suite tree')
  request.call(:get, "/executionsuites/#{execution.id}", {version: version.name, environment: environment.id})
  check.call(!session.response.body.include?(hidden_issue.subject), 'private cases are omitted from execution tree')
  request.call(:get, '/testcases', {object_id: issue.id})
  request.call(:post, '/testsuites', {parent_id: suite.id, name: 'New child'})
  request.call(:put, "/testsuites/#{suite.id}", {parent_id: suite.id}, 404)
  request.call(:put, "/testcases/#{issue.id}", {result: 'Passed', version: version.name,
                                              envs: environment.id, comment: 'Browser-compatible execution'})
  check.call(test_case.execution_journals.count == 1, 'execution journal is actually saved')
  request.call(:get, '/executionjournals', {issue_id: issue.id})
  request.call(:post, '/executionjournals', {testcase_id: issue.id, environment: environment.name,
                                            title: 'Fehler mit Umlauten', description: 'Ein reproduzierbarer Fehler', version: version.name})
  bug = Issue.find(JSON.parse(session.response.body)['issue_id'])
  check.call(bug.subject.start_with?('Fehlgeschlagener Test') && bug.relations.any?, 'created bug has a localized subject and a testcase relation')
  request.call(:get, '/graph/0', {version_id: version.id, environment_id: environment.id, suite_id: execution.id})
  check.call(JSON.parse(session.response.body).any? { |segment| segment['label'] == 'Bestanden' && segment['value'] == 1 },
             'German chart labels preserve result counts')
  request.call(:get, '/executionsuites', {get_results: true, version_id: version.id,
                                         environment_id: environment.id, suite_id: execution.id})
  report = Nokogiri::HTML.fragment(session.response.body)
  check.call(report.at_css('option[value="Passed"]')&.text == 'Bestanden' && report.at_css('option[value="not_passed"]')&.text == 'Nicht bestanden' &&
             report.at_css('tr[name="Passed"]')&.text&.include?('Bestanden'), 'translated report uses stable filter values')
  request.call(:get, '/export', {export_to: 'excel', suite_id: execution.id,
                                version_id: version.id, environment_id: environment.id})
  check.call(session.response.body.include?('Browser-compatible execution'), 'CSV contains execution comment')
  check.call(session.response.body.include?('Nr.,Testsuite,Titel') && session.response.body.include?('Bestanden'), 'CSV headers and results are German')
  check.call(!session.response.body.include?(hidden_issue.subject), 'CSV respects private issue visibility')
  request.call(:get, '/export', {export_to: 'rtf', suite_id: execution.id})
  check.call(session.response.body.start_with?('{\\rtf'), 'RTF exporter autoloads and creates a document')
  check.call(session.response.body.include?('Testfallspezifikation') && session.response.body.include?('Beschreibung'), 'RTF labels are German')
  check.call(!session.response.body.include?(hidden_issue.subject), 'RTF respects private issue visibility')
  request.call(:get, '/export', {export_to: 'invalid', suite_id: -1}, 400)
  request.call(:get, '/testcases', {object_id: foreign_issue.id}, 404)
  request.call(:get, '/testcases', {object_id: hidden_issue.id}, 404)
  request.call(:get, '/executionjournals', {issue_id: foreign_issue.id}, 404)
  request.call(:get, '/get_attachment_urls', {issue_id: foreign_issue.id}, 404)
  request.call(:put, "/environments/#{foreign_environment.id}", {execution_environment: {name: 'Intrusion'}}, 404)
  request.call(:post, '/testsuites', {parent_id: foreign_root.id, name: 'Intrusion'}, 404)
  request.call(:get, "/executionsuites/#{foreign_execution.id}", {}, 404)
  request.call(:put, "/testcases/#{issue.id}", {result: 'Passed', version: version.name,
                                              envs: foreign_environment.id}, 404)
  request.call(:post, '/environments', {execution_environment: {name: 'Scoped', project_id: foreign_project.id}})
  check.call(ExecutionEnvironment.find(JSON.parse(session.response.body)['id']).project_id == project.id,
             'strong parameters prevent changing the environment project')
  User.current = user
  issue.reload.update!(fixed_version: version)
  hidden_issue.reload.update!(fixed_version: version)
  I18n.with_locale(:de) do
    roadmap = RedcaseOverride::RO.instance.view_projects_roadmap_version_bottom(version: version)
    check.call(roadmap.include?('Testfälle insgesamt') && roadmap.include?('<b>1</b>'),
               'German roadmap summary excludes private test cases')
  end
  check.call(TestGraph.get_data(version.id, environment.id, child_execution.id, project.id)['Passed'] == 1,
             'nested execution suite result is counted')
  empty_execution = ExecutionSuite.create!(name: 'Empty execution', project: project)
  check.call(TestGraph.get_data(version.id, environment.id, empty_execution.id, project.id).values.sum == 0,
             'graph excludes cases outside selected suite')
  check.call(test_case.change_execution_suite?(child_execution.id, child_execution.id) &&
             test_case.execution_suites.reload.include?(child_execution), 'moving within the same suite preserves membership')
  Member.create!(project: foreign_project, user: user, roles: [role])
  foreign_project.versions.create!(name: version.name)
  issue.reload.update!(fixed_version: version, category: project.issue_categories.create!(name: 'Smoke category'))
  foreign_project.issue_categories.create!(name: 'Smoke category')
  request.call(:post, "/testcases/#{issue.id}/copy", {dest_project: foreign_project.id})
  copied_issue = foreign_project.issues.find_by!(subject: issue.subject)
  check.call(copied_issue.test_case.present? && copied_issue.fixed_version.project_id == foreign_project.id &&
             copied_issue.category.project_id == foreign_project.id, 'copy maps category/version and creates testcase linkage')
  role.update!(permissions: [:view_issues, :execute_test_cases])
  user.memberships.reset
  User.current = nil
  request.call(:get, "/executionsuites/#{execution.id}")
  request.call(:get, '/graph/0', {version_id: version.id, environment_id: environment.id, suite_id: execution.id})
  request.call(:put, "/testcases/#{issue.id}", {parent_id: root.id}, 403)
  request.call(:put, "/testcases/#{issue.id}", {result: 'Failed', version: version.name, envs: environment.id})
  role.update!(permissions: [:view_issues, :view_test_cases])
  User.current = nil
  request.call(:put, "/testcases/#{issue.id}", {result: 'Passed', version: version.name, envs: environment.id}, 403)
  test_case.execution_journals.update_all(executor_id: nil)
  request.call(:get, '/executionsuites', {get_results: true, version_id: version.id,
                                         environment_id: environment.id, suite_id: execution.id})
  version.destroy!
  session.get base
  check.call(session.response.status == 200, 'project with no version renders')
  check.call(session.response.body.include?('Legen Sie eine Version an'), 'missing-version guidance is German')
  raise ActiveRecord::Rollback
end
User.current = nil
I18n.with_locale(:en) do
  check.call(RedcaseTranslation.result_label('Passed') == 'Passed', 'English result labels remain available')
end
I18n.with_locale(:pl) do
  check.call(RedcaseTranslation.text('label_test_case_report') == 'Raport' && RedcaseTranslation.text('label_test_cases') == 'Test cases',
             'existing Polish labels and English fallback both work')
end
check.call(ExecutionResult.find_by!(name: 'Passed').name == 'Passed', 'stored result names remain unchanged')
puts "#{checks} checks passed; test records rolled back."
