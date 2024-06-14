defmodule Bookshelf.Books.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :title, :string
    field :language, :string
    field :description, :string
    field :publisher, :string
    field :date, :date
    field :serie_index, :decimal
    field :file, :binary
    field :filename, :string
    field :cover, :binary
    field :cover_filename, :string
    field :cover_type, :string

    timestamps(type: :utc_datetime)

    belongs_to :serie, Bookshelf.Series.Serie
    belongs_to :author, Bookshelf.Authors.Author
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :language, :description, :publisher, :date])
    |> validate_required([:title, :file])
  end
end
