defmodule BookshelfWeb.SerieController do
  use BookshelfWeb, :controller

  alias Bookshelf.Series

  def index(conn, _params) do
    series = Series.list_series()
    render(conn, :index, series: series)
  end

  def show(conn, %{"id" => id}) do
    serie = Series.get_serie!(id)
    render(conn, :show, serie: serie)
  end

  def edit(conn, %{"id" => id}) do
    serie = Series.get_serie!(id)
    changeset = Series.change_serie(serie)
    render(conn, :edit, serie: serie, changeset: changeset)
  end

  def update(conn, %{"id" => id, "serie" => serie_params}) do
    serie = Series.get_serie!(id)

    case Series.update_serie(serie, serie_params) do
      {:ok, serie} ->
        conn
        |> put_flash(:info, "Serie updated successfully.")
        |> redirect(to: ~p"/series/#{serie}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, serie: serie, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    serie = Series.get_serie!(id)
    {:ok, _serie} = Series.delete_serie(serie)

    conn
    |> put_flash(:info, "Serie deleted successfully.")
    |> redirect(to: ~p"/series")
  end

  def download(conn, %{"serie_id" => id}) do
    serie = Series.get_serie!(id)
    filename = "#{serie.title}.zip"
    books =
      serie.books
      |> Enum.map(fn book -> {String.to_charlist(book.filename), book.file} end)

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
