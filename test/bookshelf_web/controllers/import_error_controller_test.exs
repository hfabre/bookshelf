defmodule BookshelfWeb.ImportErrorControllerTest do
  use BookshelfWeb.ConnCase

  import Bookshelf.ImportErrorsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  describe "index" do
    test "lists all import_errors", %{conn: conn} do
      conn = get(conn, ~p"/import_errors")
      assert html_response(conn, 200) =~ "Listing Import errors"
    end
  end

  describe "new import_error" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/import_errors/new")
      assert html_response(conn, 200) =~ "New Import error"
    end
  end

  describe "create import_error" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/import_errors", import_error: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/import_errors/#{id}"

      conn = get(conn, ~p"/import_errors/#{id}")
      assert html_response(conn, 200) =~ "Import error #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/import_errors", import_error: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Import error"
    end
  end

  describe "edit import_error" do
    setup [:create_import_error]

    test "renders form for editing chosen import_error", %{conn: conn, import_error: import_error} do
      conn = get(conn, ~p"/import_errors/#{import_error}/edit")
      assert html_response(conn, 200) =~ "Edit Import error"
    end
  end

  describe "update import_error" do
    setup [:create_import_error]

    test "redirects when data is valid", %{conn: conn, import_error: import_error} do
      conn = put(conn, ~p"/import_errors/#{import_error}", import_error: @update_attrs)
      assert redirected_to(conn) == ~p"/import_errors/#{import_error}"

      conn = get(conn, ~p"/import_errors/#{import_error}")
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, import_error: import_error} do
      conn = put(conn, ~p"/import_errors/#{import_error}", import_error: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Import error"
    end
  end

  describe "delete import_error" do
    setup [:create_import_error]

    test "deletes chosen import_error", %{conn: conn, import_error: import_error} do
      conn = delete(conn, ~p"/import_errors/#{import_error}")
      assert redirected_to(conn) == ~p"/import_errors"

      assert_error_sent 404, fn ->
        get(conn, ~p"/import_errors/#{import_error}")
      end
    end
  end

  defp create_import_error(_) do
    import_error = import_error_fixture()
    %{import_error: import_error}
  end
end
