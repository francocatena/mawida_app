class Period < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include Periods::DateColumns
  include Periods::DestroyValidation
  include Periods::Overrides
  include Periods::Scopes
  include Periods::Validation

  belongs_to :organization
  has_many :plans
  has_many :reviews
  has_many :workflows
end
