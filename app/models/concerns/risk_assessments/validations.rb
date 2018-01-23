module RiskAssessments::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :description, presence: true, pdf_encoding: true
    validates :period, :risk_assessment_template, presence: true
    validates :period_id, uniqueness: true, allow_nil: true, allow_blank: true
    validates :name, length: { maximum: 255 }, allow_blank: true, uniqueness: {
      case_sensitive: false, scope: :organization_id
    }
  end
end
