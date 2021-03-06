class CreateVersions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :versions do |t|
      t.references :item, :polymorphic => true
      t.string :event, :null => false
      t.integer :whodunnit
      t.text :object
      t.datetime :created_at
      t.boolean :important
      t.references :organization
    end

    add_index :versions, [:item_type, :item_id]
    add_index :versions, :whodunnit
    add_index :versions, :organization_id
    add_index :versions, :created_at
    add_index :versions, :important
  end

  def self.down
    remove_index :versions, :column => [:item_type, :item_id]
    remove_index :versions, :column => :whodunnit
    remove_index :versions, :column => :organization_id
    remove_index :versions, :column => :created_at
    remove_index :versions, :column => :important

    drop_table :versions
  end
end
