module Findings::Unconfirmed
  extend ActiveSupport::Concern

  included do
    scope :unconfirmed_for_notification, -> {
      where(
        [
          'first_notification_date >= :stale_unconfirmed_date',
          'state = :state',
          'final = :false'
        ].join(' AND '),
        {
          state: Finding::STATUS[:unconfirmed],
          false: false,
          stale_unconfirmed_date: FINDING_STALE_UNCONFIRMED_DAYS.days.ago_in_business.to_date
        }
      )
    }
  end

  module ClassMethods
    def notify_for_unconfirmed_for_notification_findings
      # Sólo si no es sábado o domingo
      if [0, 6].exclude? Time.zone.today.wday
        Finding.transaction do
          users = Finding.unconfirmed_for_notification.inject([]) do |u, finding|
            u | finding.users.select do |user|
              user.notifications.not_confirmed.any? do |n|
                n.findings.include?(finding)
              end
            end
          end

          users.each { |user| NotifierMailer.stale_notification(user).deliver_later }
        end
      end
    end
  end
end
