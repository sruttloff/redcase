
class Redcase::ExportController < Redcase::BaseController
	before_action :find_project, :authorize

	def index
		project_suite(ExecutionSuite, params[:suite_id]) if params[:suite_id].to_i >= 0
		project_name = @project.name.gsub(' ', '_');
		current_time = Time.now.strftime('%d%m%Y-%I%M%S')
		filename = "TCReport-#{project_name}-#{current_time}"
		case params[:export_to]
			when 'excel'
				doc = export_to_excel
			when 'rtf'
				doc = export_to_rtf
			else
				return head :bad_request
		end
		send_data(
			doc[:document], {
				:filename => "#{filename}.#{doc[:extension]}"
			}
		)
	end

	private

	def export_to_excel
		@project.versions.find(params[:version_id])
		@project.execution_environments.find(params[:environment_id])
		excelDoc = ExcelExporter.exportTestResults(
			@project.id,
			params[:suite_id],
			params[:version_id],
			params[:environment_id]
		)
		{
			:document => excelDoc,
			:extension => 'csv'
		}
	end

	def export_to_rtf
		rtfDoc = RtfExporter.exportTestSuiteSpec(
			params[:suite_id].to_i,
			@project
		)
		{
			:document => rtfDoc,
			:extension => 'rtf'
		}
	end

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id])
	end

end

