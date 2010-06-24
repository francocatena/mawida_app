class Detract < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Named scopes
  named_scope :for_organization, lambda { |organization|
    {
      :conditions => { :organization_id => organization.id }
    }
  }

  # Restricciones sobre los atributos
  attr_readonly :organization_id
  attr_protected :organization_id

  # Restricciones
  validates_presence_of :value, :user_id
  validates_numericality_of :value, :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => 1, :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :user
  belongs_to :organization

  def initialize(attributes = nil)
    super(attributes)

    self.organization_id = GlobalModelConfig.current_organization_id
  end
end