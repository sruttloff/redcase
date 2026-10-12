class Redcase::BaseController < ApplicationController
  helper RedcaseHelper

  private

  def project_test_cases
    TestCase.joins(:issue).merge(Issue.visible(User.current).where(project_id: @project.id))
  end

  # Legacy nested suites store the project on their root only.
  def project_suite(model, id)
    suite = model.find(id)
    raise ActiveRecord::RecordNotFound unless suite.root.project_id == @project.id
    suite
  end

  def move_suite(suite, parent_id)
    parent = project_suite(suite.class, parent_id)
    if parent == suite || parent.ancestors.include?(suite) || suite.parent.nil?
      raise ActiveRecord::RecordNotFound
    end
    suite.parent = parent
  end
end
