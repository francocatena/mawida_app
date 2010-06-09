class ControlObjective < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Callbacks
  before_destroy :can_be_destroyed?
  
  # Named scopes
  named_scope :list, :order => ['process_control_id ASC',
    "#{table_name}.order ASC"].join(', ')
  named_scope :list_for_process_control, lambda { |process_control|
    {
      :conditions => {:process_control_id => process_control.id},
      :order => ['process_control_id ASC', "#{table_name}.order ASC"].join(', ')
    }
  }

  # Restricciones
  validates_presence_of :name
  validates_numericality_of :relevance, :risk, :only_integer => true,
    :allow_nil => true, :allow_blank => true
  validates_uniqueness_of :name, :case_sensitive => false,
    :scope => :process_control_id
  validates_each :controls do |record, attr, value|
    has_active_controls = value &&
      value.reject(&:marked_for_destruction?).size > 0
    
    record.errors.add attr, :blank unless has_active_controls
  end
  
  # Relaciones
  belongs_to :process_control
  has_many :control_objective_items, :dependent => :nullify
  has_many :procedure_control_subitems, :dependent => :nullify
  has_many :controls, :as => :controllable, :dependent => :destroy,
    :order => "#{Control.table_name}.order ASC"

  accepts_nested_attributes_for :controls, :allow_destroy => true

  def initialize(attributes = nil)
    super(attributes)

    self.controls.build if self.controls.blank?
  end

  def can_be_destroyed?
    unless self.control_objective_items.blank? &&
        self.procedure_control_subitems.blank?
      self.errors.add_to_base I18n.t(:'control_objective.errors.related')

      false
    else
      true
    end
  end
end