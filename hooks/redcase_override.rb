
# Callback methods to subscribe on Redmine events

module RedcaseOverride

  class RO < Redmine::Hook::ViewListener

   	def controller_issues_edit_after_save(context = { })
		# context[:journal] may be a Journal or an id; normalize to id
		jid = context[:journal].respond_to?(:id) ? context[:journal].id : context[:journal]
		journal_details = JournalDetail.find_by(journal_id: jid, prop_key: 'tracker_id')
		return if journal_details.nil?
		tracker = Tracker.find_by(name: 'Test case')
		return unless tracker
		if journal_details.prop_key == 'tracker_id'
			if journal_details.value == tracker.id.to_s
				controller_issues_new_after_save(context)
			elsif journal_details.old_value == tracker.id.to_s
				tc = TestCase.find_by(issue_id: context[:issue].id)
				tc.destroy if !tc.nil?
			end
		end
	end

    def controller_issues_new_after_save(context = { })
      if context[:issue].tracker.name != "Test case" then
        return
      end
      root = TestSuite.get_root_for_project(context[:issue].project)
      root_execution_suite = ExecutionSuite.get_root_for_project(context[:issue].project)
      x = TestCase.create(:issue => context[:issue], :test_suite => root.children.detect { |o| o.name == ".Unsorted" } )
    end

    def view_projects_roadmap_version_bottom(context = { })
      issues = Issue.visible(User.current).where(fixed_version_id: context[:version].id).collect { |x| x.id }
      test_cases = TestCase.where({issue_id: issues})
      results = ExecutionResult.all
      txt = "<span style='color: red'>#{ERB::Util.html_escape(RedcaseTranslation.text('label_total_test_cases'))}:</span> <b>" + test_cases.size.to_s + "</b>"
      for r in results do
        count = 0
        for t in test_cases do
          journals = ExecutionJournal.where({test_case_id: t.id, result_id: r.id})
          count = count + journals.size if !journals.nil?
        end
        txt = txt + " [" + ERB::Util.html_escape(RedcaseTranslation.result_label(r.name)) + "=" + count.to_s + "]"
      end
      txt = txt + "<br/>"
    end

  end

end
