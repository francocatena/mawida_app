module LoginRecords::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where(organization_id: Organization.current_id) }

    scope :between, ->(conditions) {
      list.
      includes(:user).
      where(conditions).
      order("#{quoted_table_name}.#{qcn('start')} DESC").
      references(:users)
    }
  end

  def end!
    update_column :end, Time.zone.now
  end
end
