module RedcaseTranslation
  def self.text(key, **options)
    fallback = I18n.t("redcase.#{key}", locale: :en, **options)
    I18n.t("redcase.#{key}", default: fallback, **options)
  end

  def self.result_labels
    text('results')
  end

  def self.result_label(name)
    result_labels.fetch(name.to_sym, name)
  end

  def self.suite_label(suite)
    key = if suite.parent.nil? && suite.name == 'Root'
            'root'
          elsif suite.is_a?(TestSuite) && suite.parent&.parent.nil?
            {'.Unsorted' => 'unsorted', '.Obsolete' => 'obsolete'}[suite.name]
          end
    key ? text("system_suites.#{key}") : suite.name
  end

  def self.client_labels
    english = I18n.t('redcase', locale: :en).select { |key, _| key.to_s.start_with?('label_') }
    english.merge(
      I18n.t('redcase', default: {}).select { |key, _| key.to_s.start_with?('label_') }
    )
  end
end
