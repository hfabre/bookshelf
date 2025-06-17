class CreateSeries < ActiveRecord::Migration[8.0]
  def change
    create_table :series do |t|
      t.string :name
      t.references :user, null: false, foreign_key: true
      t.string :completion_state
      t.string :reading_state
      t.integer :rating

      t.timestamps
    end

    add_index :series, [ :user_id, :name ], unique: true
  end
end
