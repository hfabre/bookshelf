class RemoveUserFromSerie < ActiveRecord::Migration[8.0]
  def change
    remove_reference :series, :user, foreign_key: true
  end
end
