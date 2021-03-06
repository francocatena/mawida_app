class CreateQuestions < ActiveRecord::Migration[4.2]
  def change
    create_table :questions do |t|
      t.integer :sort_order
      t.integer :answer_type
      t.text :question
      t.references :questionnaire
      t.integer :lock_version, :default => 0
      t.timestamps null: false
    end

    add_index :questions, :questionnaire_id
  end
end
