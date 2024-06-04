defmodule BookshelfWeb.AuthorController do
  use BookshelfWeb, :controller

  alias Bookshelf.Authors
  alias Bookshelf.Authors.Author

  def index(conn, _params) do
    authors = Authors.list_authors()
    render(conn, :index, authors: authors)
  end

  def show(conn, %{"id" => id}) do
    author = Authors.get_author!(id)
    render(conn, :show, author: author)
  end

  def delete(conn, %{"id" => id}) do
    author = Authors.get_author!(id)
    {:ok, _author} = Authors.delete_author(author)

    conn
    |> put_flash(:info, "Author deleted successfully.")
    |> redirect(to: ~p"/authors")
  end

  def download(conn, %{"author_id" => id}) do
    author = Authors.get_author!(id)
    filename = "#{author.name}.zip"
    books =
      author.books
      |> Enum.map(fn book -> {String.to_charlist("#{book.serie.title}/#{book.filename}"), book.file} end)

    case :zip.zip(String.to_charlist(filename), books, [:memory]) do
      {:ok, {_zip_filename, zip}} ->
        conn
        |> send_download({:binary, zip}, filename: filename)
      {:error, reason} ->
        conn
        |> put_flash(:error, "Unable to build zip, error: #{reason}")
        |> redirect(to: ~p"/series")
    end
  end
end
