class RemoveProcedureControls < ActiveRecord::Migration[4.2]
  def change
    drop_table :procedure_control_subitems
    drop_table :procedure_control_items
    drop_table :procedure_controls
  end
end
