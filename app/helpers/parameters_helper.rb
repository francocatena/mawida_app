module ParametersHelper
  include Parameters::Risk
  include Parameters::Relevance
  include Parameters::Qualification

  def relevance_field(form, *options)
    form.select :relevance,
      RELEVANCE_TYPES.map { |k,v| [t("relevance_types.#{k}"), v] }, *options
  end

  def qualification_field(form, field, *options)
    form.select field,
      QUALIFICATION_TYPES.map { |k,v| [t("qualification_types.#{k}"), v] }, *options
  end

  def risk_field(form, *options)
    form.select :risk,
      RISK_TYPES.map { |k,v| [t("risk_types.#{k}"), v] }, *options
  end
end
