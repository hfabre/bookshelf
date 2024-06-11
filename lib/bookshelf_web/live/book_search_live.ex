defmodule BookshelfWeb.BookSearchLive do
  use BookshelfWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, books: Bookshelf.Books.random_list, query: ""), layout: false}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, query: query, books: Bookshelf.Books.search(query))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form class="my-10">
      <input phx-change="search" phx-debounce="100" value={@query} autocomplete={false} placeholder="Search..." name="query" class="border-2 rounded"/>
    </form>

    <.book_list books={@books} />
    """
  end
end
