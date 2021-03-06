module Tasks::Expiration
  extend ActiveSupport::Concern

  included do
    scope :expired, -> {
      pending.or(in_progress).finals(false).where(
        "#{quoted_table_name}.#{qcn 'due_on'} < ?", Time.zone.today
      )
    }
  end

  def expired?
    (pending? || in_progress?) && due_on < Time.zone.today
  end

  module ClassMethods
    def expires_very_soon
      date = if Time.zone.now < Time.zone.now.noon
       Time.zone.today
     else
       1.day.business_days.from_now.to_date
     end

      expires_on date
    end

    def next_to_expire
      expires_on FINDING_WARNING_EXPIRE_DAYS.business_days.from_now.to_date
    end

    def finals final
      includes(:finding).merge(Finding.finals(final)).references :findings
    end

    def warning_users_about_expiration
      # Sólo si no es sábado o domingo (porque no tiene sentido)
      if Time.zone.today.workday?
        users = next_to_expire.or(expires_very_soon).inject([]) do |u, task|
          u | task.users
        end

        users.each do |user|
          tasks = user.tasks.next_to_expire.or user.tasks.expires_very_soon

          NotifierMailer.tasks_expiration_warning(user, tasks.to_a).deliver_later
        end
      end
    end

    def remember_users_about_expiration
      users = expired.inject([]) do |u, task|
        u | task.users
      end

      users.each do |user|
        NotifierMailer.
          tasks_expired_warning(user, user.tasks.expired.to_a).
          deliver_later
      end
    end

    private

      def expires_on date
        from = date
        to   = expires_to_date from

        pending.or(in_progress).finals(false).where due_on: from..to
      end

      def expires_to_date date
        date = date.next until date.next.workday?

        date
      end
  end
end
