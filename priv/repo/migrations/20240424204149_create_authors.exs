defmodule Bookshelf.Repo.Migrations.CreateAuthors do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create(
      unique_index(
        :authors,
        :name,
        name: :index_uniq_authors_name
      )
    )
  end
end
