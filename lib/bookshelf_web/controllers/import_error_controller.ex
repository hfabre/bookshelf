defmodule BookshelfWeb.ImportErrorController do
  use BookshelfWeb, :controller

  alias Bookshelf.ImportErrors

  def index(conn, _params) do
    import_errors = ImportErrors.list_import_errors()
    render(conn, :index, import_errors: import_errors)
  end

  def delete(conn, %{"id" => id}) do
    import_error = ImportErrors.get_import_error!(id)
    {:ok, _import_error} = ImportErrors.delete_import_error(import_error)

    conn
    |> put_flash(:info, "Import error deleted successfully.")
    |> redirect(to: ~p"/import_errors")
  end
end
