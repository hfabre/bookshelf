defmodule BookshelfWeb.BookController do
  use BookshelfWeb, :controller

  alias Bookshelf.Books

  def index(conn, _params) do
    books = Books.random_list()
    render(conn, :index, books: books)
  end

  def edit(conn, %{"id" => id}) do
    book = Books.get_book!(id)
    changeset = Books.change_book(book)
    render(conn, :edit, book: book, changeset: changeset)
  end

  def update(conn, %{"id" => id, "book" => book_params}) do
    book = Books.get_book!(id)

    case Books.update_book(book, book_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Book updated successfully.")
        |> redirect(to: ~p"/books")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, book: book, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    book = Books.get_book!(id)
    {:ok, _book} = Books.delete_book(book)

    conn
    |> put_flash(:info, "Book deleted successfully.")
    |> redirect(to: ~p"/books")
  end

  def download(conn, %{"book_id" => id}) do
    book = Books.get_book!(id)

    conn
    |> send_download({:binary, book.file}, filename: book.filename)
  end
end
