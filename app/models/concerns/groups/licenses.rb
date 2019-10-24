module Groups::Licenses
  extend ActiveSupport::Concern

  included do
    scope :licensed, -> { where licensed: true }

    attr_accessor :users_left_count
  end

  def auditors_limit
    licensed? ? license.auditors_limit : Rails.application.credentials.auditors_limit
  end

  def can_create_auditor?
    self.users_left_count = (
      auditors_limit - users.can_act_as(:auditor).unscope(:order).distinct.select('users.id').count
    )

    users_left_count.positive?
  end
end
