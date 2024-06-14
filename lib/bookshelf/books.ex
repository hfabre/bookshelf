defmodule Bookshelf.Books do
  @moduledoc """
  The Books context.
  """

  import Ecto.Query, warn: false
  alias Bookshelf.Repo

  alias Bookshelf.Books.Book

  @doc """
  Returns the list of books.

  ## Examples

      iex> list_books()
      [%Book{}, ...]

  """
  def list_books(options \\ []) do
    default = [limit: 1_000_000, offset: 0]
    options = Keyword.merge(default, options)
    q = from b in Book, limit: ^options[:limit], offset: ^options[:offset]

    Repo.all(q)
    |> Repo.preload(:serie)
  end

  def search(query, options \\ []) do
    default = [limit: 1_000_000, offset: 0]
    options = Keyword.merge(default, options)
    ilike = "%#{query}%"
    q = from b in Book, where: ilike(b.title, ^ilike), limit: ^options[:limit], offset: ^options[:offset]

    Repo.all(q)
    |> Repo.preload(:serie)
  end

  def count(query) do
    ilike = "%#{query}%"
    q = from b in Book, select: count(b.id), where: ilike(b.title, ^ilike)

    Repo.one(q)
  end

  def random_list(options \\ []) do
    default = [limit: 1_000_000, offset: 0]
    options = Keyword.merge(default, options)
    query = from Book, order_by: fragment("RANDOM()"), limit: ^options[:limit], offset: ^options[:offset]

    Repo.all(query)
    |> Repo.preload(:serie)
  end

  @doc """
  Gets a single book.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> get_book!(123)
      %Book{}

      iex> get_book!(456)
      ** (Ecto.NoResultsError)

  """
  def get_book!(id) do
    Repo.get!(Book, id)
    |> Repo.preload(:serie)
    |> Repo.preload(:author)
  end

  @doc """
  Updates a book.

  ## Examples

      iex> update_book(book, %{field: new_value})
      {:ok, %Book{}}

      iex> update_book(book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_book(%Book{} = book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a book.

  ## Examples

      iex> delete_book(book)
      {:ok, %Book{}}

      iex> delete_book(book)
      {:error, %Ecto.Changeset{}}

  """
  def delete_book(%Book{} = book) do
    Repo.delete(book)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.

  ## Examples

      iex> change_book(book)
      %Ecto.Changeset{data: %Book{}}

  """
  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end
end
