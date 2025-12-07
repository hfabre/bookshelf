class CreateSeriesFtsTable < ActiveRecord::Migration[8.0]
  def change
    create_virtual_table :series_fts, :fts5, [ 'name', 'user_id UNINDEXED' ]
  end
end
