class Comment < ActiveRecord::Base
  include ParameterSelector

  has_paper_trail meta: { organization_id: ->(obj) { Organization.current_id } }

  # Restricciones
  validates :comment, :presence => true

  # Relaciones
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
end
