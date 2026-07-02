class AddFailureDetailsToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :failure_message, :text
    add_column :books, :job_id, :string
  end
end
