defmodule Bookshelf.ImportErrorsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bookshelf.ImportErrors` context.
  """

  @doc """
  Generate a import_error.
  """
  def import_error_fixture(attrs \\ %{}) do
    {:ok, import_error} =
      attrs
      |> Enum.into(%{

      })
      |> Bookshelf.ImportErrors.create_import_error()

    import_error
  end
end
