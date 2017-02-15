class RemoveCostPerUnitFromResources < ActiveRecord::Migration
  def change
    remove_column :resources, :cost_per_unit
    remove_column :resource_utilizations, :cost_per_unit
  end
end
