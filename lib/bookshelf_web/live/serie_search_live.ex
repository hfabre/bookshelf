defmodule BookshelfWeb.SerieSearchLive do
  use BookshelfWeb, :live_view

  @item_per_page 30

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, series: Bookshelf.Series.list_series(limit: @item_per_page), query: "", current_page: 1), layout: false}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    current_page = Map.get(socket.assigns, :current_page)
    {:noreply, assign(socket, query: query, series: Bookshelf.Series.search(query, limit: @item_per_page, offset: offset(current_page)))}
  end

  def handle_event("incr_page", _, socket) do
    current_page = Map.get(socket.assigns, :current_page)
    query = Map.get(socket.assigns, :query)
    item_count = Bookshelf.Series.count(query)
    max_page = ceil(item_count / @item_per_page)

    new_page = if current_page >= max_page, do: max_page, else: current_page + 1
    {:noreply, assign(socket, series: Bookshelf.Series.search(query, limit: @item_per_page, offset: offset(new_page)), current_page: new_page)}
  end

  def handle_event("decr_page", _, socket) do
    current_page = Map.get(socket.assigns, :current_page)
    query = Map.get(socket.assigns, :query)

    new_page = if current_page == 1, do: 1, else: current_page - 1
    {:noreply, assign(socket, series: Bookshelf.Series.search(query, limit: @item_per_page, offset: offset(new_page)), current_page: new_page)}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <form class="my-10">
      <input phx-change="search" phx-debounce="100" value={@query} autocomplete={false} placeholder="Search..." name="query" class="border-2 rounded"/>
    </form>

    <div id="series" class="grid grid-cols-5 gap-8">
      <article class="overflow-hidden rounded-lg border border-gray-100 bg-white shadow-sm" :for={serie <- @series}>
        <% book = Bookshelf.Series.get_serie!(serie.id).books |> Enum.at(0) %>
        <.link href={~p"/series/#{serie}"}>
          <div class="aspect-[2.8/4] w-full relative overflow-hidden">
            <img class="object-cover w-full h-full absolute scale-110 blur" src={"data:#{book.cover_type};base64, #{book.cover}"} alt={"#{book.title} cover"} />
            <img class="object-contain w-full h-full absolute" src={"data:#{book.cover_type};base64, #{book.cover}"} alt={"#{book.title} cover"} />
          </div>

          <div class="p-4 sm:p-6">
            <h3 class="text-sm font-medium text-gray-900">
              <%= "#{serie.title} (#{Enum.count(serie.books)})" %>
            </h3>

            <p class="mt-2 line-clamp-3 text-xs/relaxed text-gray-500">
              Completion state: <%= serie.completion_state || "unknown" %>
              <br />
              Reading state: <%= serie.reading_state || "unknown" %>

              <div class="flex justify-center p-6" :if={serie.rating}>
                <%= for x <- 1..5 do %>
                  <.star filled={Ecto.Enum.mappings(Bookshelf.Series.Serie, :rating)[serie.rating] >= x} />
                <% end %>
              </div>
            </p>
          </div>
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
