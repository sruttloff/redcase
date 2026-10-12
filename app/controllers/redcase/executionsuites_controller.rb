
class Redcase::ExecutionsuitesController < Redcase::BaseController
	before_action :find_project, :authorize

	def index
		if params[:get_results].nil?
			@list2 = ExecutionSuite.find_by(project_id: @project.id)
			@version = Version
				.where(project_id: @project.id)
				.order(created_on: :desc)
				.first
			render :partial => 'redcase/execution_list'
		else
			@environment = @project.execution_environments.find_by(id: params[:environment_id])
			@version = @project.versions.find_by(id: params[:version_id])
			@root_execution_suite = project_suite(ExecutionSuite, params[:suite_id]) if params[:suite_id].to_i >= 0
			@results = ExecutionSuite.get_results(
				@environment,
				@version,
				params[:suite_id].to_i,
				@project.id
			)
			render :partial => 'redcase/report_results'
		end
	end

	def show
		unless params[:version].nil?
			version = Version.find_by(name: params[:version], project_id: @project.id)
		end
		unless params[:environment].nil?
			environment = @project.execution_environments.find(params[:environment])
		end

		render :json => project_suite(ExecutionSuite, params[:id]).to_json(
			view_context, version, environment
		)
	end

	def create
		execution_suite =
			# TODO: Compute project id first, then user ExecutionSuite.create
			#       just once.
			if params[:parent_id].nil?
				ExecutionSuite.create!(
					:name => params[:name],
					:project_id => @project.id
				)
			else
				ExecutionSuite.create!(
					:name => params[:name],
					:parent => project_suite(ExecutionSuite, params[:parent_id])
				)
			end
		render :json => execution_suite.to_json(view_context)
	end

	def update
		execution_suite = project_suite(ExecutionSuite, params[:id])
		move_suite(execution_suite, params[:parent_id]) unless params[:parent_id].nil?
		execution_suite.name = params[:new_name] unless params[:new_name].nil?
		execution_suite.save
		render :json => { :success => true }
	end

	def destroy
		project_suite(ExecutionSuite, params[:id]).destroy!
		render :json => { :success => true }
	end

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id])
	end

end

