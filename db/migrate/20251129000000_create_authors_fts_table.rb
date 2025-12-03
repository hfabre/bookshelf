class CreateAuthorsFtsTable < ActiveRecord::Migration[8.0]
  def change
    create_virtual_table :authors_fts, :fts5, [ 'name', 'user_id UNINDEXED' ]
  end
end
