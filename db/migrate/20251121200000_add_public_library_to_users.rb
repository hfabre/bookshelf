class AddPublicLibraryToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :public_library, :boolean, default: false, null: false
  end
end
