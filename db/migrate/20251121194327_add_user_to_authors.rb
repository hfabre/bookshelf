class AddUserToAuthors < ActiveRecord::Migration[8.0]
  def change
    add_reference :authors, :user, null: false, foreign_key: true
    remove_index :authors, [ :name ]
    add_index :authors, [ :user_id, :name ], unique: true
  end
end
