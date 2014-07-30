module Users::Notifications
  extend ActiveSupport::Concern

  def send_welcome_email
    NotifierMailer.delay.welcome_email(self) unless send_notification_email.blank?
  end

  def send_notification_if_necesary
    if send_notification_email.present?
      organization = Organization.find Organization.current_id

      reset_password organization, notify: false

      NotifierMailer.delay.welcome_email(self)
    end
  end

  module ClassMethods
    def notify_new_findings
      unless [0, 6].include?(Date.today.wday)
        users, findings = [], []

        all_with_findings_for_notification.each do |user|
          users << user

          findings |= user.findings.for_notification
        end

        Finding.transaction do
          raise ActiveRecord::Rollback unless findings.all? &:mark_as_unconfirmed!
        end

        users.each { |user| NotifierMailer.delay.notify_new_findings(user) }
      end
    end
  end
end
