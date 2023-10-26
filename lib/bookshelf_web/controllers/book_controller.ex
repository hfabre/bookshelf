defmodule BookshelfWeb.BookController do
  use BookshelfWeb, :controller

  alias Bookshelf.Books
  alias Bookshelf.Books.Book

  def index(conn, _params) do
    books = Books.list_books()
    render(conn, "index.html", books: books)
  end

  def new(conn, _params) do
    changeset = Books.change_book(%Book{})
    authors = Books.list_authors()
    render(conn, "new.html", authors: authors, changeset: changeset)
  end

  def create(conn, %{"book" => book_params}) do
    case Books.create_book(book_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Book created successfully.")
        |> redirect(to: Routes.live_books_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", authors: Books.list_authors(), changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    book = Books.get_book!(id)
    render(conn, "show.html", book: book)
  end

  def edit(conn, %{"id" => id}) do
    book = Books.get_book!(id)
    changeset = Books.change_book(book)
    authors = Books.list_authors()
    render(conn, "edit.html", book: book, authors: authors, changeset: changeset)
  end

  def update(conn, %{"id" => id, "book" => book_params}) do
    book = Books.get_book!(id)

    case Books.update_book(book, book_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Book updated successfully.")
        |> redirect(to: Routes.live_books_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", book: book, authors: Books.list_authors(), changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    book = Books.get_book!(id)
    {:ok, _book} = Books.delete_book(book)

    conn
    |> put_flash(:info, "Book deleted successfully.")
    |> redirect(to: Routes.book_path(conn, :index))
  end

  def download(conn, %{"book_id" => id}) do
    book = Books.get_book!(id)

    conn
    |> send_download({:binary, book.file}, filename: book.filename)
  end
end
