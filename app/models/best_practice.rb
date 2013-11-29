class BestPractice < ActiveRecord::Base
  include ParameterSelector
  include PaperTrail::DependentDestroy
  include Associations::DestroyInBatches

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Callbacks
  #before_destroy :can_be_destroyed?

  # Named scopes
  scope :list, -> {
    where(organization_id: Organization.current_id).order('name ASC')
  }

  # Restricciones
  validates :name, :organization_id, presence: true
  validates :name, length: { maximum: 255 }, allow_nil: true, allow_blank: true
  validates :organization_id, numericality: { only_integer: true },
    allow_blank: true, allow_nil: true
  validates :name, uniqueness: { case_sensitive: false, scope: :organization_id }
  validates_each :process_controls do |record, attr, value|
    unless value.all? {|pc| !pc.marked_for_destruction? || pc.can_be_destroyed?}
      record.errors.add attr, :locked
    end
  end

  # Relaciones
  belongs_to :organization
  has_many :process_controls, -> { order("#{ProcessControl.table_name}.order ASC") },
    :dependent => :destroy,
    :after_add => :assign_best_practice

  accepts_nested_attributes_for :process_controls, :allow_destroy => true

  def assign_best_practice(process_control)
    process_control.best_practice = self
  end

  def can_be_destroyed?
    unless self.process_controls.all? {|pc| pc.can_be_destroyed?}
      errors = self.process_controls.map do |pc|
        pc.errors.full_messages.join(APP_ENUM_SEPARATOR)
      end

      self.errors.add :base, errors.reject { |e| e.blank? }.join(
        APP_ENUM_SEPARATOR)

      false
    else
      true
    end
  end
end
