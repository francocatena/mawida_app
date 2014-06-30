class User < ActiveRecord::Base
  include ActsAsTree
  include AttrSearchable
  include Comparable
  include ParameterSelector
  include Trimmer
  include Users::Auditable
  include Users::Authorization
  include Users::CustomAttributes
  include Users::Defaults
  include Users::DestroyValidation
  include Users::Findings
  include Users::JSON
  include Users::MarkChanges
  include Users::Name
  include Users::Notifications
  include Users::Password
  include Users::Polls
  include Users::Reassigns
  include Users::Relations
  include Users::Releases
  include Users::Resources
  include Users::Roles
  include Users::Scopes
  include Users::Search
  include Users::Validations
  include Users::Tree

  trimmed_fields :user, :email, :name, :last_name
  attr_searchable :user, :name, :last_name, :function

  has_many :login_records, dependent: :destroy
  has_many :error_records, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :review_user_assignments, dependent: :destroy
  has_many :reviews, -> { uniq }, through: :review_user_assignments

  def <=>(other)
    other.kind_of?(User) ? id <=> other.id : -1
  end

  def to_s
    user
  end

  def to_param
    user_changed? ? user_was : user
  end
end
