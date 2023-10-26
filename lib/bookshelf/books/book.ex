defmodule Bookshelf.Books.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :title, :string
    field :file, :binary
    field :note, Ecto.Enum, values: [very_bad: 0, bad: 1, neutral: 2, good: 3, very_good: 4, awesome: 5]
    field :completion_state, Ecto.Enum, values: [:in_progress, :finished]
    field :reading_state, Ecto.Enum, values: [:waiting, :in_progress, :finished]
    field :comment, :string
    field :filename, :string
    field :author, :string

    timestamps()
  end

  @doc false
  def changeset(book, %{"file" => file} = attrs) when is_struct(file, Plug.Upload) do
    attrs =
      with {:ok, file} <- File.open(attrs["file"].path, [:read, :binary]),
          content <- IO.binread(file, :eof),
          :ok <- File.close(file) do
        dup = Map.put(attrs, "file", content)
        Map.put(dup, "filename", attrs["file"].filename)
      end

    changeset(book, attrs)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :file, :note, :completion_state, :reading_state, :comment, :filename, :author])
    |> validate_required([:title, :completion_state, :reading_state, :note])
  end
end
