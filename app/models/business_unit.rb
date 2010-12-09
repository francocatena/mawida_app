class BusinessUnit < ActiveRecord::Base
  include Trimmer

  trimmed_fields :name

  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Callbacks
  before_destroy :can_be_destroyed?

  # Restricciones
  validates :name, :presence => true
  validates :name, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates :name, :uniqueness =>
    {:case_sensitive => false, :scope => :business_unit_type_id}
  
  # Relaciones
  belongs_to :business_unit_type
  has_many :plan_items, :dependent => :destroy

  def can_be_destroyed?
    unless self.plan_items.empty?
      self.errors.add :base,
        I18n.t(:'business_unit_type.errors.business_unit_related')

      false
    else
      true
    end
  end
end