class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title
      t.text :description
      t.string :language
      t.date :date
      t.string :publisher
      t.references :serie, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :serie_index
      t.binary :epub_content
      t.string :filename
      t.binary :cover_bytes
      t.string :cover_type
      t.string :processing_status

      t.timestamps
    end

    add_index :books, [ :user_id, :serie_id, :serie_index ], unique: true
  end
end
