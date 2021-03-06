class Cost < ApplicationRecord
  include Auditable

  # Named scopes
  scope :audit, -> { where(:cost_type => 'audit') }
  scope :audited, -> { where(:cost_type => 'audited') }

  # Restricciones
  validates :cost, :cost_type, :user_id, :item_id, :item_type, :presence => true
  validates :user_id, :item_id, :numericality => {:only_integer => true},
    :allow_nil => true, :allow_blank => true
  validates :cost, :numericality => {
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => 9_999_999_999_999.99
  }, :allow_nil => true, :allow_blank => true
  validates :description, :pdf_encoding => true

  # Relaciones
  belongs_to :user
  belongs_to :item, -> { readonly }, :polymorphic => true, :touch => true

  def raw_cost=(raw_cost)
    self.cost = raw_cost.fetch_time / 3600.0 unless raw_cost.blank?
  end

  def raw_cost
    self.cost.try(:to_s)
  end
end
