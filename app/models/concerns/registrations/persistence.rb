module Registrations::Persistence
  extend ActiveSupport::Concern

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      group        = create_group
      organization = create_organization group
      user         = create_user organization

      NotifierMailer.welcome_email(user).deliver_later

      user
    rescue ActiveRecord::RecordInvalid => ex
      ::Rails.logger.error ex

      errors.add :base, ex.message

      raise ActiveRecord::Rollback
    end
  rescue ActiveRecord::Rollback
    false
  end

  private

    def create_group
      Group.create!(
        name:                    organization_name,
        admin_email:             email,
        description:             organization_name,
        send_notification_email: false
      )
    end

    def create_organization group
      group.organizations.create!(
        name:        organization_name,
        prefix:      organization_name.parameterize,
        description: organization_name
      )
    end

    def create_user organization
      user = User.new(
        user:      self.user,
        name:      self.name,
        last_name: self.last_name,
        email:     self.email,
        language:  'es',
        enable:    true
      )

      role = organization.roles.admin

      user.organization_roles.build organization: organization, role: role
      user.save!
    end
end
