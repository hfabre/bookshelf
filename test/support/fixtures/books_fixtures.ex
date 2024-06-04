defmodule Bookshelf.BooksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bookshelf.Books` context.
  """

  @doc """
  Generate a book.
  """
  def book_fixture(attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> Enum.into(%{

      })
      |> Bookshelf.Books.create_book()

    book
  end
end
