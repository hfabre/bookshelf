defmodule Bookshelf.Repo.Migrations.CreateImportErrors do
  use Ecto.Migration

  def change do
    create table(:import_errors) do
      add :book_title, :string, null: false
      add :log, :text
      add :stacktrace, :text

      timestamps(type: :utc_datetime)
    end
  end
end
