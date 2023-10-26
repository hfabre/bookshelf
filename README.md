# Bookshelf

Bookshelf is a tiny web app made to manage your collection of readings.
Since I usually read series of book is usually create one `Book` per serie.
When creating your book you can also upload a file to it, for me it's the zip file
containing all serie's ebooks.

Books data include:

- a title
- an author
- a comment
- a note
- a file to store ebook file
- a reading state (still reading or finished)
- a completion state (still begin written or finished)

You can search by author or title in realtime with [liveview](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html).

## Technical details

Bookshelf is written in [Elixir](https://elixir-lang.org/) using [Phoenix](https://www.phoenixframework.org/).
Your bookshelf is protect behind a simple HTTP authentication (`USERNAME` and `PASSWORD` environment variable are used, defaulting to `user` / `password`)
To keep things simple uploaded file are simply written directly into the database.

## Development

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
