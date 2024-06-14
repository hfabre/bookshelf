defmodule BookshelfWeb.BookSearchLive do
  use BookshelfWeb, :live_view

  @item_per_page 30

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, books: Bookshelf.Books.list_books(limit: @item_per_page), query: "", current_page: 1), layout: false}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    current_page = Map.get(socket.assigns, :current_page)
    {:noreply, assign(socket, query: query, books: Bookshelf.Books.search(query, limit: @item_per_page, offset: offset(current_page)))}
  end

  def handle_event("incr_page", _, socket) do
    current_page = Map.get(socket.assigns, :current_page)
    query = Map.get(socket.assigns, :query)
    item_count = Bookshelf.Books.count(query)
    max_page = ceil(item_count / @item_per_page)

    new_page = if current_page >= max_page, do: max_page, else: current_page + 1
    {:noreply, assign(socket, books: Bookshelf.Books.search(query, limit: @item_per_page, offset: offset(new_page)), current_page: new_page)}
  end

  def handle_event("decr_page", _, socket) do
    current_page = Map.get(socket.assigns, :current_page)
    query = Map.get(socket.assigns, :query)

    new_page = if current_page == 1, do: 1, else: current_page - 1
    {:noreply, assign(socket, books: Bookshelf.Books.search(query, limit: @item_per_page, offset: offset(new_page)), current_page: new_page)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form class="my-10">
      <input phx-change="search" phx-debounce="100" value={@query} autocomplete={false} placeholder="Search..." name="query" class="border-2 rounded"/>
    </form>

    <.book_list books={@books} />

    <.pagination current_page={@current_page} />
    """
  end

  defp offset(page) do
    (page - 1) * @item_per_page
  end
end
