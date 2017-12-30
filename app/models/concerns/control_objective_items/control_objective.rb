module ControlObjectiveItems::ControlObjective
  extend ActiveSupport::Concern

  included do
    delegate :support, :support?, to: :control_objective

    belongs_to :control_objective, inverse_of: :control_objective_items
    has_one :process_control, through: :control_objective
    has_one :best_practice, through: :process_control
  end
end
