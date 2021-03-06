module RiskAssessmentItems::Weights
  extend ActiveSupport::Concern

  included do
    has_many :risk_weights, -> {
      joins(:risk_assessment_weight).
        order Arel.sql("#{RiskAssessmentWeight.quoted_table_name}.#{RiskAssessmentWeight.qcn 'id'}")
    }, dependent: :destroy, inverse_of: :risk_assessment_item

    accepts_nested_attributes_for :risk_weights, allow_destroy: true, reject_if: :all_blank
    validates_associated :risk_weights, if: :final?
  end

  def build_risk_weights
    risk_assessment_template = risk_assessment.risk_assessment_template

    risk_assessment_template.risk_assessment_weights.each do |raw|
      risk_weights.build(
        weight:                    raw.weight,
        risk_assessment_weight_id: raw.id
      )
    end
  end
end
