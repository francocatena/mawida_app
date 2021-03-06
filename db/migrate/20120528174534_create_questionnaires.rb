class CreateQuestionnaires < ActiveRecord::Migration[4.2]
  def change
    create_table :questionnaires do |t|
      t.string :name
      t.integer :lock_version, :default => 0
      t.timestamps null: false
    end

    add_index :questionnaires, :name
  end
end
