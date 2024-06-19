defmodule Bookshelf.ImportErrorsTest do
  use Bookshelf.DataCase

  alias Bookshelf.ImportErrors

  describe "import_errors" do
    alias Bookshelf.ImportErrors.ImportError

    import Bookshelf.ImportErrorsFixtures

    @invalid_attrs %{}

    test "list_import_errors/0 returns all import_errors" do
      import_error = import_error_fixture()
      assert ImportErrors.list_import_errors() == [import_error]
    end

    test "get_import_error!/1 returns the import_error with given id" do
      import_error = import_error_fixture()
      assert ImportErrors.get_import_error!(import_error.id) == import_error
    end

    test "create_import_error/1 with valid data creates a import_error" do
      valid_attrs = %{}

      assert {:ok, %ImportError{} = import_error} = ImportErrors.create_import_error(valid_attrs)
    end

    test "create_import_error/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ImportErrors.create_import_error(@invalid_attrs)
    end

    test "update_import_error/2 with valid data updates the import_error" do
      import_error = import_error_fixture()
      update_attrs = %{}

      assert {:ok, %ImportError{} = import_error} = ImportErrors.update_import_error(import_error, update_attrs)
    end

    test "update_import_error/2 with invalid data returns error changeset" do
      import_error = import_error_fixture()
      assert {:error, %Ecto.Changeset{}} = ImportErrors.update_import_error(import_error, @invalid_attrs)
      assert import_error == ImportErrors.get_import_error!(import_error.id)
    end

    test "delete_import_error/1 deletes the import_error" do
      import_error = import_error_fixture()
      assert {:ok, %ImportError{}} = ImportErrors.delete_import_error(import_error)
      assert_raise Ecto.NoResultsError, fn -> ImportErrors.get_import_error!(import_error.id) end
    end

    test "change_import_error/1 returns a import_error changeset" do
      import_error = import_error_fixture()
      assert %Ecto.Changeset{} = ImportErrors.change_import_error(import_error)
    end
  end
end
