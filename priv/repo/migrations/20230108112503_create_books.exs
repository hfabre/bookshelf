defmodule Bookshelf.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string, unique: true, null: false
      add :file, :binary
      add :note, :integer, null: false
      add :completion_state, :string, null: false
      add :reading_state, :string, null: false
      add :comment, :text
      add :filename, :string
      add :author, :string

      timestamps()
    end
  end
end
