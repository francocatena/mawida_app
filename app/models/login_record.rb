class LoginRecord < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include LoginRecords::Defaults
  include LoginRecords::Validations
  include LoginRecords::Search
  include LoginRecords::Scopes

  attr_accessor :request

  belongs_to :user
  belongs_to :organization
end
