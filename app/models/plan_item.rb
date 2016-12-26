class PlanItem < ActiveRecord::Base
  include Auditable
  include Comparable
  include ParameterSelector
  include PlanItems::Comparable
  include PlanItems::Cost
  include PlanItems::DestroyValidation
  include PlanItems::Pdf
  include PlanItems::Predecessors
  include PlanItems::ResourceUtilizations
  include PlanItems::Scopes
  include PlanItems::Status
  include PlanItems::Validations
  include Taggable

  attr_accessor :overloaded

  belongs_to :plan
  belongs_to :business_unit
  has_one :review
  has_one :business_unit_type, through: :business_unit
end
