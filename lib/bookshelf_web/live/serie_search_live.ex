defmodule BookshelfWeb.SerieSearchLive do
  use BookshelfWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, series: Bookshelf.Series.list_series, query: ""), layout: false}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, query: query, series: Bookshelf.Series.search(query))}
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
          <img class="min-h-56" src={"data:#{book.cover_type};base64, #{book.cover}"} alt={"#{book.title} cover"} />

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
    """
  end
end
