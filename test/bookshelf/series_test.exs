defmodule Bookshelf.SeriesTest do
  use Bookshelf.DataCase

  alias Bookshelf.Series

  describe "series" do
    alias Bookshelf.Series.Serie

    import Bookshelf.SeriesFixtures

    @invalid_attrs %{}

    test "list_series/0 returns all series" do
      serie = serie_fixture()
      assert Series.list_series() == [serie]
    end

    test "get_serie!/1 returns the serie with given id" do
      serie = serie_fixture()
      assert Series.get_serie!(serie.id) == serie
    end

    test "create_serie/1 with valid data creates a serie" do
      valid_attrs = %{}

      assert {:ok, %Serie{} = serie} = Series.create_serie(valid_attrs)
    end

    test "create_serie/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Series.create_serie(@invalid_attrs)
    end

    test "update_serie/2 with valid data updates the serie" do
      serie = serie_fixture()
      update_attrs = %{}

      assert {:ok, %Serie{} = serie} = Series.update_serie(serie, update_attrs)
    end

    test "update_serie/2 with invalid data returns error changeset" do
      serie = serie_fixture()
      assert {:error, %Ecto.Changeset{}} = Series.update_serie(serie, @invalid_attrs)
      assert serie == Series.get_serie!(serie.id)
    end

    test "delete_serie/1 deletes the serie" do
      serie = serie_fixture()
      assert {:ok, %Serie{}} = Series.delete_serie(serie)
      assert_raise Ecto.NoResultsError, fn -> Series.get_serie!(serie.id) end
    end

    test "change_serie/1 returns a serie changeset" do
      serie = serie_fixture()
      assert %Ecto.Changeset{} = Series.change_serie(serie)
    end
  end
end
