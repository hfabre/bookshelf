defmodule BookshelfWeb.SerieController do
  use BookshelfWeb, :controller

  alias Bookshelf.Series
  alias Bookshelf.Series.Serie

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
end
