
class Redcase::TestcasesController < Redcase::BaseController
	before_action :find_project, :authorize

	def index
		# TODO: What if there is none?
		test_case = project_test_cases.find_by!(issue_id: params[:object_id])
		render :json => test_case.to_json(view_context)
	end

	def copy
		destination_project = Project.find(params[:dest_project])
		unless User.current.allowed_to?(:add_issues, destination_project)
			raise ::Unauthorized
		end
		# TODO: What if there is none?
		test_case = project_test_cases.find_by!(issue_id: params[:id])
		test_case.copy_to(destination_project)
		render :json => { :success => true }
	end

	def update
		permission = params[:result].present? ? :execute_test_cases : :edit_test_cases
		return render_403 unless User.current.allowed_to?(permission, @project)
		if params[:result].present?
			return execute(project_test_cases.find_by!(issue_id: params[:id]))
		end
		# TODO: What if there is none?
		test_case = project_test_cases.find_by!(issue_id: params[:id])
		success = true
		[:source_exec_id, :dest_exec_id, :remove_from_exec_id].each do |key|
			project_suite(ExecutionSuite, params[key]) if params[key].present?
		end
		if params[:parent_id].present?
			test_case.test_suite = project_suite(TestSuite, params[:parent_id])
		end
		if params[:source_exec_id].present? && params[:dest_exec_id].present?
			success = test_case.change_execution_suite?(params[:source_exec_id], params[:dest_exec_id])
		elsif params[:dest_exec_id].present?
			success = test_case.add_to_execution_suite?(params[:dest_exec_id])
		end
		if params[:remove_from_exec_id].present?
			test_case.remove_from_execution_suite(params[:remove_from_exec_id])
		end
		test_case.test_suite = TestSuite.get_obsolete(@project) if params[:obsolesce].present?
		test_case.save!
		render :json => { :success => success }
	end

	private

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id])
	end

	def execute(test_case)
		version = @project.versions.find_by!(name: params[:version])
		comment = params[:comment].blank? ? nil : params[:comment]
		result = ExecutionResult.find_by!(name: params[:result])
		environment = @project.execution_environments.find(params[:envs])
		ExecutionJournal.create!(
			version: version,
			comment: comment,
			test_case: test_case,
			result: result,
			executor: User.current,
			environment: environment
		)
		render :json => ExecutionJournal
			.where({ test_case_id: test_case.id })
			.order(created_on: :desc)
			.collect { |ej| ej.to_json }
	end

end

