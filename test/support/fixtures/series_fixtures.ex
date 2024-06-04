defmodule Bookshelf.SeriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bookshelf.Series` context.
  """

  @doc """
  Generate a serie.
  """
  def serie_fixture(attrs \\ %{}) do
    {:ok, serie} =
      attrs
      |> Enum.into(%{

      })
      |> Bookshelf.Series.create_serie()

    serie
  end
end
