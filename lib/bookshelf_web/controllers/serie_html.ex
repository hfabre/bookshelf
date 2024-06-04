defmodule BookshelfWeb.SerieHTML do
  use BookshelfWeb, :html

  embed_templates "serie_html/*"

  @doc """
  Renders a serie form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def serie_form(assigns)
end
