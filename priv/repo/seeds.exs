# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Bookshelf.Repo.insert!(%Bookshelf.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Bookshelf.Repo.insert!(%Bookshelf.Books.Book{
  title: "L'assassin royal",
  note: :awesome,
  completion_state: :finished,
  reading_state: :finished,
  author: "Robin Hoob"
})

Bookshelf.Repo.insert!(%Bookshelf.Books.Book{
  title: "Harry Potter",
  note: :awesome,
  completion_state: :finished,
  reading_state: :finished,
  author: "J.K Rowling"
})

Bookshelf.Repo.insert!(%Bookshelf.Books.Book{
  title: "Neutral book",
  note: :neutral,
  completion_state: :finished,
  reading_state: :in_progress,
  author: "An Author"
})

Bookshelf.Repo.insert!(%Bookshelf.Books.Book{
  title: "In progress book",
  note: :good,
  completion_state: :in_progress,
  reading_state: :finished,
  author: "An Author"
})
