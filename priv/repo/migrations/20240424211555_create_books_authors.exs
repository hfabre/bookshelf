defmodule Bookshelf.Repo.Migrations.CreateBooksAuthors do
  use Ecto.Migration

  def change do
    create table(:books_authors, primary_key: false) do
      add :book_id, references(:books)
      add :author_id, references(:authors)
    end

    create unique_index(:books_authors, [:book_id, :author_id])
  end
end
