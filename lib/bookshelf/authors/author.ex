defmodule Bookshelf.Authors.Author do
  use Ecto.Schema
  import Ecto.Changeset

  schema "authors" do
    field :name, :string

    timestamps(type: :utc_datetime)

    has_many :books, Bookshelf.Books.Book
  end

  @doc false
  def changeset(author, attrs) do
    author
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :index_uniq_authors_name)
  end
end
