defmodule Bookshelf.Authors do
  @moduledoc """
  The Authors context.
  """

  import Ecto.Query, warn: false
  alias Bookshelf.Repo

  alias Bookshelf.Authors.Author

  @doc """
  Returns the list of authors.

  ## Examples

      iex> list_authors()
      [%Author{}, ...]

  """
  def list_authors(options \\ []) do
    default = [limit: 1_000_000, offset: 0]
    options = Keyword.merge(default, options)
    q = from a in Author, limit: ^options[:limit], offset: ^options[:offset]

    Repo.all(q)
    |> Repo.preload(:books)
  end

  def search(query, options \\ []) do
    default = [limit: 1_000_000, offset: 0]
    options = Keyword.merge(default, options)
    ilike = "%#{query}%"
    q = from a in Author, where: ilike(a.name, ^ilike), limit: ^options[:limit], offset: ^options[:offset]

    Repo.all(q)
    |> Repo.preload(:books)
  end

  def count(query) do
    ilike = "%#{query}%"
    q = from a in Author, select: count(a.id), where: ilike(a.name, ^ilike)

    Repo.one(q)
  end

  @doc """
  Gets a single author.

  Raises `Ecto.NoResultsError` if the Author does not exist.

  ## Examples

      iex> get_author!(123)
      %Author{}

      iex> get_author!(456)
      ** (Ecto.NoResultsError)

  """
  def get_author!(id) do
    Repo.get!(Author, id)
    |> Repo.preload(books: [:serie, :author])
  end

  @doc """
  Updates a author.

  ## Examples

      iex> update_author(author, %{field: new_value})
      {:ok, %Author{}}

      iex> update_author(author, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_author(%Author{} = author, attrs) do
    author
    |> Author.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a author.

  ## Examples

      iex> delete_author(author)
      {:ok, %Author{}}

      iex> delete_author(author)
      {:error, %Ecto.Changeset{}}

  """
  def delete_author(%Author{} = author) do
    Repo.delete(author)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking author changes.

  ## Examples

      iex> change_author(author)
      %Ecto.Changeset{data: %Author{}}

  """
  def change_author(%Author{} = author, attrs \\ %{}) do
    Author.changeset(author, attrs)
  end
end
