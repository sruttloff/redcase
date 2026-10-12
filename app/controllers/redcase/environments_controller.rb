
class Redcase::EnvironmentsController < Redcase::BaseController
	helper RedcaseHelper
	before_action :find_project, :authorize

	def index
		environment = @project.execution_environments.find(
			params[:execution_environment_id]
		)
		render(
			:partial => 'redcase/management_environments',
			:locals => { :project => @project, :environment => environment }
		)
	end

	def create
		environment = @project.execution_environments.create!(environment_params)
		render :json => environment
	end

	def update
		environment = @project.execution_environments.find(params[:id])
		environment.update!(environment_params)
		# TODO: Properly handle the case when this fails.
		render :json => { :success => true }
	end

	def destroy
		environment = @project.execution_environments.find(params[:id])
		environment.destroy
		# TODO: Properly handle the case when this fails.
		render :json => { :success => true }
	end

	# TODO: This one is being used across all the controllers, a good sign for
	#       creating a common (parent) controller with this method in it to
	#       share in descendants.
	def find_project
		@project = Project.find(params[:project_id])
	end

	private

	def environment_params
		params.require(:execution_environment).permit(:name, :description)
	end

end

