defmodule BookshelfWeb.BookControllerTest do
  use BookshelfWeb.ConnCase

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

  describe "index" do
    test "lists all books", %{conn: conn} do
      conn = get(conn, Routes.book_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Books"
    end
  end

  describe "new book" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.book_path(conn, :new))
      assert html_response(conn, 200) =~ "New Book"
    end
  end

  describe "create book" do
    test "redirects to index when data is valid", %{conn: conn} do
      conn = post(conn, Routes.book_path(conn, :create), book: @create_attrs)
      assert redirected_to(conn) == Routes.live_books_path(conn, :index)

      conn = get(conn, Routes.live_books_path(conn, :index))
      assert html_response(conn, 200) =~ "Books"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.book_path(conn, :create), book: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Book"
    end
  end

  describe "edit book" do
    setup [:create_book]

    test "renders form for editing chosen book", %{conn: conn, book: book} do
      conn = get(conn, Routes.book_path(conn, :edit, book))
      assert html_response(conn, 200) =~ "Edit Book"
    end
  end

  describe "update book" do
    setup [:create_book]

    test "redirects when data is valid", %{conn: conn, book: book} do
      conn = put(conn, Routes.book_path(conn, :update, book), book: @update_attrs)
      assert redirected_to(conn) == Routes.live_books_path(conn, :index)

      conn = get(conn, Routes.live_books_path(conn, :index))
      assert html_response(conn, 200) =~ "Books"
    end

    test "renders errors when data is invalid", %{conn: conn, book: book} do
      conn = put(conn, Routes.book_path(conn, :update, book), book: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Book"
    end
  end

  describe "delete book" do
    setup [:create_book]

    test "deletes chosen book", %{conn: conn, book: book} do
      conn = delete(conn, Routes.book_path(conn, :delete, book))
      assert redirected_to(conn) == Routes.book_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.book_path(conn, :show, book))
      end
    end
  end

  defp create_book(_) do
    book = book_fixture(@create_attrs)
    %{book: book}
  end
end
