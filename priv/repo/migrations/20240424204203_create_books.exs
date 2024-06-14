defmodule Bookshelf.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string, null: false
      add :language, :string
      add :description, :text
      add :publisher, :string
      add :date, :date

      add :file, :binary, null: false
      add :filename, :string

      add :cover, :binary
      add :cover_filename, :string
      add :cover_type, :string

      add :serie_id, references(:series)
      add :serie_index, :decimal

      add :author_id, references(:authors)

      timestamps(type: :utc_datetime)
    end
  end
end
