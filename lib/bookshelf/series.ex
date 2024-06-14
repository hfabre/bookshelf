defmodule Bookshelf.Series do
  @moduledoc """
  The Series context.
  """

  import Ecto.Query, warn: false
  alias Bookshelf.Repo

  alias Bookshelf.Series.Serie

  @doc """
  Returns the list of series.

  ## Examples

      iex> list_series()
      [%Serie{}, ...]

  """
  def list_series(options \\ []) do
    default = [limit: 1_000_000, offset: 0]
    options = Keyword.merge(default, options)
    query = from Serie, order_by: fragment("rating DESC NULLS LAST"), limit: ^options[:limit], offset: ^options[:offset]

    Repo.all(query)
    |> Repo.preload(:books)
  end

  def search(query, options \\ []) do
    default = [limit: 1_000_000, offset: 0]
    options = Keyword.merge(default, options)
    ilike = "%#{query}%"
    q = from s in Serie, where: ilike(s.title, ^ilike), order_by: fragment("rating DESC NULLS LAST"), limit: ^options[:limit], offset: ^options[:offset]

    Repo.all(q)
    |> Repo.preload(:books)
  end

  def count(query) do
    ilike = "%#{query}%"
    q = from s in Serie, select: count(s.id), where: ilike(s.title, ^ilike)

    Repo.one(q)
  end
  @doc """
  Gets a single serie.

  Raises `Ecto.NoResultsError` if the Serie does not exist.

  ## Examples

      iex> get_serie!(123)
      %Serie{}

      iex> get_serie!(456)
      ** (Ecto.NoResultsError)

  """
  def get_serie!(id) do
    Repo.get!(Serie, id)
    |> Repo.preload(books: :serie)
  end

  @doc """
  Updates a serie.

  ## Examples

      iex> update_serie(serie, %{field: new_value})
      {:ok, %Serie{}}

      iex> update_serie(serie, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_serie(%Serie{} = serie, attrs) do
    chgset = Serie.changeset(serie, attrs)
    IO.inspect(chgset)
    Repo.update(chgset)
  end

  @doc """
  Deletes a serie.

  ## Examples

      iex> delete_serie(serie)
      {:ok, %Serie{}}

      iex> delete_serie(serie)
      {:error, %Ecto.Changeset{}}

  """
  def delete_serie(%Serie{} = serie) do
    Repo.delete(serie)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking serie changes.

  ## Examples

      iex> change_serie(serie)
      %Ecto.Changeset{data: %Serie{}}

  """
  def change_serie(%Serie{} = serie, attrs \\ %{}) do
    Serie.changeset(serie, attrs)
  end
end
