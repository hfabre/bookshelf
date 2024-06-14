defmodule BookshelfWeb.AuthorSearchLive do
  use BookshelfWeb, :live_view

  @item_per_page 30

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, authors: Bookshelf.Authors.list_authors(limit: @item_per_page), query: "", current_page: 1), layout: false}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    current_page = Map.get(socket.assigns, :current_page)
    {:noreply, assign(socket, query: query, authors: Bookshelf.Authors.search(query, limit: @item_per_page, offset: offset(current_page)))}
  end

  def handle_event("incr_page", _, socket) do
    current_page = Map.get(socket.assigns, :current_page)
    query = Map.get(socket.assigns, :query)
    item_count = Bookshelf.Authors.count(query)
    max_page = ceil(item_count / @item_per_page)

    new_page = if current_page >= max_page, do: max_page, else: current_page + 1
    {:noreply, assign(socket, authors: Bookshelf.Authors.search(query, limit: @item_per_page, offset: offset(new_page)), current_page: new_page)}
  end

  def handle_event("decr_page", _, socket) do
    current_page = Map.get(socket.assigns, :current_page)
    query = Map.get(socket.assigns, :query)

    new_page = if current_page == 1, do: 1, else: current_page - 1
    {:noreply, assign(socket, authors: Bookshelf.Authors.search(query, limit: @item_per_page, offset: offset(new_page)), current_page: new_page)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form class="my-10">
      <input phx-change="search" phx-debounce="100" value={@query} autocomplete={false} placeholder="Search..." name="query" class="border-2 rounded"/>
    </form>

    <div id="authors" class="grid grid-cols-5 gap-8">
      <article class="overflow-hidden rounded-lg border border-gray-100 bg-white shadow-sm" :for={author <- @authors}>
        <% book = Bookshelf.Authors.get_author!(author.id).books |> Enum.at(0) %>
        <.link href={~p"/authors/#{author}"}>
          <img class="min-h-56" src={"data:#{book.cover_type};base64, #{book.cover}"} alt={"#{book.title} cover"} />

          <div class="p-4 sm:p-6">
            <h3 class="text-sm font-medium text-gray-900">
              <%= author.name %>
            </h3>
          </div>
        </.link>

        <.link href={~p"/authors/#{author.id}/download"}>
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3" />
          </svg>
        </.link>
      </article>
    </div>
    <.pagination current_page={@current_page} />
    """
  end

  defp offset(page) do
    (page - 1) * @item_per_page
  end
end
