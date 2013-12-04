class InlineHelp < ActiveRecord::Base
  include Associations::DestroyPaperTrail

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Restricciones
  validates :language, :name, :presence => true
  validates :name, :uniqueness => {:scope => :language}, :allow_nil => true,
    :allow_blank => true
  validates :language, :length => {:maximum => 10}, :allow_nil => true,
    :allow_blank => true
  validates :name, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
end
