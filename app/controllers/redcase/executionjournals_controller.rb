
class Redcase::ExecutionjournalsController < Redcase::BaseController
	before_action :find_project, :authorize

	def index
		journals =
			if !params[:issue_id].nil?
				project_test_cases.find_by!(issue_id: params[:issue_id]).execution_journals.order(created_on: :desc)
			else
				ExecutionJournal.where(test_case_id: project_test_cases.select(:id)).order(created_on: :desc)
			end
		render :json => journals.map(&:to_json)
	end

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id])
	end

	def create
		return render_403 unless User.current.allowed_to?(:add_issues, @project)
		testcase = project_test_cases.find_by!(issue_id: params[:testcase_id]).issue
		user = User.current
		tracker = @project.trackers.find_by(name: "Bug")
		status = IssueStatus.find_by(name: "New")
		version = Version.find_by(project_id: @project.id, name: params[:version])
		issue = Issue.new(
			:author => user,
			:project => @project,
			:tracker => tracker
		)
		issue.subject = RedcaseTranslation.text('text_failed_issue_subject', environment: params[:environment].to_s, title: params[:title].to_s)
		issue.description = "#{params[:description]}"
		issue.fixed_version = version
		issue.save!

		IssueRelation.create!(:relation_type => 'relates', :issue_from => issue, :issue_to => testcase)

		Rails.logger.info "created issue #{issue.id}"

		render :json => { :success => true, :issue_id => issue.id }
	end
end

