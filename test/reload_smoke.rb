# bundle exec rails runner plugins/redcase/test/reload_smoke.rb
# Isolate repeated plugin initialization to Redcase in this runner process.
# Other installed plugins may have their own unrelated reload failures.
raise 'Use development or test' unless Rails.env.development? || Rails.env.test?
STDOUT.sync = true
Redmine::PluginLoader.singleton_class.prepend(Module.new do
  def directories
    super.select { |directory| File.basename(directory.to_s) == 'redcase' }
  end
end)

3.times do |iteration|
  Rails.application.reloader.reload!
  [[Issue, IssuePatch, :test_case], [Project, ProjectPatch, :test_suite],
   [Version, VersionPatch, :execution_journals], [User, UserPatch, :execution_journals]].each do |model, patch, association|
    raise "Missing patch on #{model}" unless model < patch && model.reflect_on_association(association)
  end
  listeners = Redmine::Hook.listeners.count { |listener| listener.class.name == 'RedcaseOverride::RO' }
  raise "Duplicate/missing Redcase listeners: #{listeners}" unless listeners == 1
  raise 'CSV exporter unavailable' unless ExcelExporter.respond_to?(:exportTestResults)
  raise 'RTF exporter unavailable' unless RtfExporter.respond_to?(:exportTestSuiteSpec)
  document = RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, 'Times New Roman'))
  RtfExporter.send(:writeTitle, document, 'Reload test', -1)
  raise 'RTF generation failed after reload' unless document.to_rtf.start_with?('{\\rtf')
  puts "PASS: reload #{iteration + 1}: associations, single hook listener, exporters and RTF generation"
end
