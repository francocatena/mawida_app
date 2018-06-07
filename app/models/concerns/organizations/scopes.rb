module Organizations::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered,   -> { order name: :asc }
    scope :corporate, -> { where corporate: true }
  end

  def users_with_roles(*roles)
    role_types = roles.map { |role| ::Role::TYPES[role.to_sym] }

    users = self.users.includes(
      organization_roles: :role
    ).where(
      roles: {
        role_type: role_types
      }
    )

    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      users.distinct
    else
      User.where id: users.pluck(:id).uniq
    end
  end

  module ClassMethods
    def with_group group
      where group_id: group.id
    end

    def by_subdomain subdomain
      where("LOWER(#{qcn('prefix')}) = ?", subdomain.to_s.downcase).take
    end
  end
end
