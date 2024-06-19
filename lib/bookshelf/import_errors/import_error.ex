defmodule Bookshelf.ImportErrors.ImportError do
  use Ecto.Schema
  import Ecto.Changeset

  schema "import_errors" do
    field :book_title, :string
    field :log, :string
    field :stacktrace, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(import_error, attrs) do
    import_error
    |> cast(attrs, [:book_title, :log, :stacktrace])
    |> validate_required([:book_title])
  end
end
