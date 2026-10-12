
class Redcase::TestsuitesController < Redcase::BaseController
	before_action :find_project, :authorize

	def index
		testsuites = TestSuite
			.get_root_for_project(@project)
			.to_json(view_context)
		render :json => testsuites
	end

	def create
		parent = project_suite(TestSuite, params[:parent_id])
		created = TestSuite.create!(
			:name => params[:name],
			:parent => parent
		)
		render :json => created.to_json(view_context)
	end

	def update
		testSuite = project_suite(TestSuite, params[:id])
		move_suite(testSuite, params[:parent_id]) unless params[:parent_id].nil?
		testSuite.name = params[:new_name] unless (params[:new_name].nil?)
		testSuite.save
		# TODO: Properly handle if failed.
		render :json => { :success => true }
	end

	def destroy
		suite = project_suite(TestSuite, params[:id])
		raise ActiveRecord::RecordNotFound if suite.parent.nil? || ['.Unsorted', '.Obsolete'].include?(suite.name)
		suite.destroy!
		# TODO: Properly handle if failed.
		render :json => { :success => true }
	end

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id])
	end

end

