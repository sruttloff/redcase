
require 'csv'
class Excel_Exporter
	def self.exportTestResults(project_id, suite_id, version_id, environment_id)
		issues = Issue.visible(User.current)
			.where({ project_id: project_id })
			.order(id: :asc)
			.pluck(:id)
		test_cases = TestCase.where({ issue_id: issues })
		versions = Version.find(version_id)
		environments = ExecutionEnvironment.find(environment_id)
		rows = []
		rows << [
			RedcaseTranslation.text('label_id'),
			RedcaseTranslation.text('label_test_suite'),
			RedcaseTranslation.text('label_title'),
			"#{versions.name}(#{environments.name})",
			RedcaseTranslation.text('label_comment')
		]
		test_cases = test_cases.sort { |a, b|
			(a.test_suite.name <=> b.test_suite.name)
		}
		test_cases.each { |test_case|
			if (suite_id.to_i < 0) || test_case.in_suite?(suite_id.to_i, project_id)
				row = []
				row << "##{test_case.issue.id}"
				row << RedcaseTranslation.suite_label(test_case.test_suite)
				row << "#{test_case.issue.subject}"
				found = ExecutionJournal
					.where(test_case_id: test_case.id, environment_id: environments.id, version_id: versions.id)
					.order(created_on: :desc)
					.first
				row << RedcaseTranslation.result_label(!found ? 'Not Executed' : found.result.name)
				if found.present?
					if found.comment.present?
						row << found.comment
					else
						# TODO: Is it needed?
						row << ''
					end
				else
					# TODO: What's the point of this?
					row << ''
				end
				rows << row.clone
			end
		}
		bom = "\357\273\277"
		bom + rows.inject('') { |buffer, row|
			buffer += CSV.generate_line(row)
			buffer
		}.force_encoding('utf-8')
	end

end


# Zeitwerk (Rails 6+) expects this file to define ExcelExporter.
# Keep backward compatibility by aliasing the original class name.
ExcelExporter = Excel_Exporter unless defined?(ExcelExporter)
