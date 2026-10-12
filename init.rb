
require 'redmine'
require 'acts_as_tree'
# Keep the listener class outside autoload paths. Re-register it if Redmine's
# hook registry is reloaded; its methods resolve the current model constants.
require_relative 'hooks/redcase_override'
unless Redmine::Hook.listeners.any? { |listener| listener.is_a?(RedcaseOverride::RO) }
  Redmine::Hook.add_listener(RedcaseOverride::RO)
end

Redmine::Plugin.register :redcase do

	name 'Redcase'
	description 'Test cases management plugin for Redmine'
	author 'Bugzinga Team'
	version '1.1.0'
	requires_redmine :version_or_higher => '6.1.0'

	permission :view_test_cases, {
		:redcase => [
			:index,
			:get_attachment_urls
		],
		'redcase/environments' => [
			:index
		],
		'redcase/testsuites' => [
			:index
		],
		'redcase/testcases' => [
			:index
		],
		'redcase/executionjournals' => [
			:index,
			:create
		],
		'redcase/export' => [
			:index
		],
		'redcase/executionsuites' => [
			:index,
			:show
		],
		'redcase/graph' => [
			:show
		],
		'redcase/combos' => [
			:index
		]
	}

	permission :edit_test_cases, {
		:redcase => [
			:index,
			:get_attachment_urls
		],
		'redcase/environments' => [
			:index,
			:update,
			:destroy,
			:create
		],
		'redcase/testsuites' => [
			:index,
			:update,
			:destroy,
			:create
		],
		'redcase/testcases' => [
			:index,
			:update,
			:destroy,
			:copy
		],
		'redcase/executionjournals' => [
			:index,
			:create
		],
		'redcase/export' => [
			:index
		],
		'redcase/executionsuites' => [
			:index,
			:update,
			:destroy,
			:create,
			:show
		],
		'redcase/graph' => [
			:show
		],
		'redcase/combos' => [
			:index
		]
	}

	permission :execute_test_cases, {
		:redcase => [
			:index,
			:get_attachment_urls
		],
		'redcase/environments' => [
			:index
		],
		'redcase/testsuites' => [
			:index
		],
		'redcase/testcases' => [
			:index,
			:update
		],
		'redcase/executionjournals' => [
			:index,
			:create
		],
		'redcase/export' => [
			:index
		],
		'redcase/executionsuites' => [
			:index,
			:show
		],
		'redcase/graph' => [
			:show
		],
		'redcase/combos' => [
			:index
		]
	}

	menu :project_menu,
		:redcase, {
			:controller => 'redcase',
			:action => 'index'
		}, {
			:if => proc { |p|
				can_view = User.current.allowed_to?(:view_test_cases, p)
				can_edit = User.current.allowed_to?(:edit_test_cases, p)
				can_execute = User.current.allowed_to?(:execute_test_cases, p)
				tracker_exists = p.trackers.any? { |t| (t.name == 'Test case') }
				(can_view || can_edit || can_execute) && tracker_exists
			},
			:caption => :'redcase.label_test_cases',
			:after => :new_issue
		}

	# Redmine runs this initializer in to_prepare, including after model reloads.
	Issue.include IssuePatch unless Issue < IssuePatch
	Project.include ProjectPatch unless Project < ProjectPatch
	Version.include VersionPatch unless Version < VersionPatch
	User.include UserPatch unless User < UserPatch

end
