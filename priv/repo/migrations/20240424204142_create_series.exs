defmodule Bookshelf.Repo.Migrations.CreateSeries do
  use Ecto.Migration

  def change do
    create table(:series) do
      add :title, :string, null: false
      add :comment, :text
      add :rating, :integer
      add :completion_state, :string
      add :reading_state, :string

      timestamps(type: :utc_datetime)
    end

    create(
      unique_index(
        :series,
        :title,
        name: :index_uniq_series_title
      )
    )
  end
end
