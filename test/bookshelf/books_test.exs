defmodule Bookshelf.BooksTest do
  use Bookshelf.DataCase

  alias Bookshelf.Books

  describe "books" do
    alias Bookshelf.Books.Book

    import Bookshelf.BooksFixtures

    @create_attrs %{
      title: "Book title",
      author: "Book Author",
      note: :awesome,
      completion_state: :finished,
      reading_state: :in_progress,
      comment: "A comment"
    }

    @update_attrs %{
      reading_state: :finished
    }

    @invalid_attrs %{
      title: nil,
      author: nil,
      note: :invalid,
      completion_state: :invalid,
      reading_state: :invalid
    }

    test "list_books/0 returns all books" do
      book = book_fixture()
      assert Books.list_books() == [book]
    end

    test "get_book!/1 returns the book with given id" do
      book = book_fixture()
      assert Books.get_book!(book.id) == book
    end

    test "create_book/1 with valid data creates a book" do
      assert {:ok, %Book{} = _} = Books.create_book(@create_attrs)
    end

    test "create_book/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Books.create_book(@invalid_attrs)
    end

    test "update_book/2 with valid data updates the book" do
      book = book_fixture()

      assert {:ok, %Book{} = _} = Books.update_book(book, @update_attrs)
    end

    test "update_book/2 with invalid data returns error changeset" do
      book = book_fixture()
      assert {:error, %Ecto.Changeset{}} = Books.update_book(book, @invalid_attrs)
      assert book == Books.get_book!(book.id)
    end

    test "delete_book/1 deletes the book" do
      book = book_fixture()
      assert {:ok, %Book{}} = Books.delete_book(book)
      assert_raise Ecto.NoResultsError, fn -> Books.get_book!(book.id) end
    end

    test "change_book/1 returns a book changeset" do
      book = book_fixture()
      assert %Ecto.Changeset{} = Books.change_book(book)
    end
  end
end
