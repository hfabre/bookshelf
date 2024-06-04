defmodule Bookshelf.AuthorsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bookshelf.Authors` context.
  """

  @doc """
  Generate a author.
  """
  def author_fixture(attrs \\ %{}) do
    {:ok, author} =
      attrs
      |> Enum.into(%{

      })
      |> Bookshelf.Authors.create_author()

    author
  end
end
