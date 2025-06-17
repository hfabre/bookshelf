class CreateBooksAuthors < ActiveRecord::Migration[8.0]
  def change
    create_table :authors_books do |t|
      t.references :book, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: true

      t.timestamps
    end

    add_index :authors_books, [ :book_id, :author_id ], unique: true
  end
end
