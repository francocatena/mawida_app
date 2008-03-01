class ErrorRecord < ActiveRecord::Base
  include ParameterSelector

  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new({
    :user => {
      :column => "LOWER(#{User.table_name}.user)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :data => {
      :column => "LOWER(#{table_name}.data)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  })

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  # Constantes
  ERRORS = {
    :on_login => 1,
    :on_password_change => 2,
    :user_disabled => 3
  }.freeze

  # Atributos no persistentes
  attr_accessor :request, :user_name, :error_type

  # Restricciones
  validates_inclusion_of :error, :in => ERRORS.values

  # Relaciones
  belongs_to :user
  belongs_to :organization

  def initialize(attributes = nil)
    super(attributes)

    self.error ||= ERRORS[self.error_type] if self.error_type

    if self.request
      self.data ||= "IP: [#{self.request.ip}], B: [#{self.request.user_agent}]"
    end

    if self.user.blank? && self.user_name
      self.data = "U: [#{self.user_name}], " + self.data
    end
  end

  def error_text
    I18n.t("error_record.error_#{ERRORS.invert[self.error]}")
  end
end