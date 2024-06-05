defmodule Bookshelf.Series.Serie do
  use Ecto.Schema
  import Ecto.Changeset

  schema "series" do
    field :title, :string
    field :comment, :string
    field :completion_state, Ecto.Enum, values: [:in_progress, :finished]
    field :reading_state, Ecto.Enum, values: [:waiting, :in_progress, :finished]
    field :rating, Ecto.Enum,
    values: [very_bad: 0, bad: 1, neutral: 2, good: 3, very_good: 4, awesome: 5]

    timestamps(type: :utc_datetime)

    has_many :books, Bookshelf.Books.Book
  end

  @doc false
  def changeset(serie, attrs) do
    serie
    |> cast(attrs, [:title, :comment, :completion_state, :reading_state, :rating])
    |> validate_required([:title])
    |> unique_constraint(:title, name: :index_uniq_series_title)
  end
end
