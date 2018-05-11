class RiskAssessment < ApplicationRecord
  include Auditable
  include RiskAssessments::CSV
  include RiskAssessments::DestroyValidation
  include RiskAssessments::FileModel
  include RiskAssessments::PDF
  include RiskAssessments::Plan
  include RiskAssessments::RiskAssessmentItems
  include RiskAssessments::Scopes
  include RiskAssessments::Search
  include RiskAssessments::Sort
  include RiskAssessments::Status
  include RiskAssessments::UpdateCallbacks
  include RiskAssessments::Validations

  belongs_to :period, optional: true
  belongs_to :plan, optional: true
  belongs_to :risk_assessment_template, optional: true
  belongs_to :organization
  has_many :risk_assessment_weights, through: :risk_assessment_template
end