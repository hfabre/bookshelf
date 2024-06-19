defmodule Bookshelf.ImportErrors do
  @moduledoc """
  The ImportErrors context.
  """

  import Ecto.Query, warn: false
  alias Bookshelf.Repo

  alias Bookshelf.ImportErrors.ImportError

  @doc """
  Returns the list of import_errors.

  ## Examples

      iex> list_import_errors()
      [%ImportError{}, ...]

  """
  def list_import_errors do
    Repo.all(ImportError)
  end

  @doc """
  Gets a single import_error.

  Raises `Ecto.NoResultsError` if the Import error does not exist.

  ## Examples

      iex> get_import_error!(123)
      %ImportError{}

      iex> get_import_error!(456)
      ** (Ecto.NoResultsError)

  """
  def get_import_error!(id), do: Repo.get!(ImportError, id)

  @doc """
  Creates a import_error.

  ## Examples

      iex> create_import_error(%{field: value})
      {:ok, %ImportError{}}

      iex> create_import_error(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_import_error(attrs \\ %{}) do
    %ImportError{}
    |> ImportError.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a import_error.

  ## Examples

      iex> update_import_error(import_error, %{field: new_value})
      {:ok, %ImportError{}}

      iex> update_import_error(import_error, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_import_error(%ImportError{} = import_error, attrs) do
    import_error
    |> ImportError.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a import_error.

  ## Examples

      iex> delete_import_error(import_error)
      {:ok, %ImportError{}}

      iex> delete_import_error(import_error)
      {:error, %Ecto.Changeset{}}

  """
  def delete_import_error(%ImportError{} = import_error) do
    Repo.delete(import_error)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking import_error changes.

  ## Examples

      iex> change_import_error(import_error)
      %Ecto.Changeset{data: %ImportError{}}

  """
  def change_import_error(%ImportError{} = import_error, attrs \\ %{}) do
    ImportError.changeset(import_error, attrs)
  end
end
