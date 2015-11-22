class ControlObjective < ActiveRecord::Base
  include Parameters::Relevance
  include Parameters::Risk
  include Associations::DestroyPaperTrail
  include Associations::DestroyInBatches

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Callbacks
  #before_destroy :can_be_destroyed?

  # Named scopes
  scope :list, -> {
    order([
      "#{quoted_table_name}.#{qcn('process_control_id')} ASC",
      "#{quoted_table_name}.#{qcn('order')} ASC"
    ])
  }
  scope :list_for_process_control, ->(process_control) {
    where(process_control_id: process_control.id).order([
      "#{quoted_table_name}.#{qcn('process_control_id')} ASC",
      "#{quoted_table_name}.#{qcn('order')} ASC"
    ])
  }

  # Restricciones
  validates :name, presence: true
  validates :relevance, :risk, numericality: { only_integer: true },
    allow_nil: true, allow_blank: true
  validates_each :control do |record, attr, value|
    has_active_control = value && !value.marked_for_destruction?

    record.errors.add attr, :blank unless has_active_control
  end

  # Relaciones
  belongs_to :process_control
  has_many :control_objective_items, inverse_of: :control_objective,
    dependent: :nullify
  has_one :control, -> { order("#{Control.quoted_table_name}.#{Control.qcn('order')} ASC") },
    as: :controllable, dependent: :destroy

  accepts_nested_attributes_for :control, allow_destroy: true

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.build_control unless self.control
  end

  def as_json(options = nil)
    default_options = {
      only: [:id],
      methods: [:label, :informal]
    }

    super(default_options.merge(options || {}))
  end

  def label
    continuous ? "#{name} (#{I18n.t('activerecord.attributes.control_objective.continuous')})" : name
  end

  def informal
    process_control.try(:name)
  end

  def can_be_destroyed?
    unless self.control_objective_items.blank?
      self.errors.add :base, I18n.t('control_objective.errors.related')

      false
    else
      true
    end
  end

  def risk_text
    risk = self.class.risks.detect { |r| r.last == self.risk }

    risk ? I18n.t("risk_types.#{risk.first}") : ''
  end
end
