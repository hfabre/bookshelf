defmodule BookshelfWeb.LiveBooks do
  use BookshelfWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    {:noreply, push_patch(socket, to: Routes.live_books_path(socket, :index, query: query))}
  end

  def handle_params(params, _url, socket) do
    query = Map.get(params, "query")
    {:noreply, assign(socket, query: query, books: Bookshelf.Books.search(query))}
  end

  def render(assigns) do
    ~H"""
    <h1>Books</h1>
    <%= render_search_form(assigns) %>

      <table>
        <thead>
          <tr>
            <th>Title</th>
            <th>Author</th>
            <th>Note</th>
            <th>Completion state</th>
            <th>Reading state</th>
            <th>Comment</th>
            <th>Date</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <%= render_books(assigns) %>
        </tbody>
      </table>
    """
  end

  def render_search_form(assigns) do
    ~H"""
    <%= form_for :search, "#", [phx_change: "search"], fn f -> %>
      <%= label f, :search %>
      <%= text_input f, :query, value: @query  %>
    <% end %>
    """
  end

  def render_books(assigns) do
    ~H"""
    <%= for book <- @books do %>
      <tr>
        <td><%= book.title %></td>
        <td><%= book.author %></td>
        <td><%= book.note %></td>
        <td><%= book.completion_state %></td>
        <td><%= book.reading_state %></td>
        <td><%= book.comment %></td>
        <td><%= Date.to_string(book.inserted_at) %></td>
        <td>
          <span><%= link "Download", to: Routes. book_download_path(@socket, :download, book) %></span>
          <span><%= link "Edit", to: Routes.book_path(@socket, :edit, book) %></span>
          <span><%= link "Delete", to: Routes.book_path(@socket, :delete, book), method: :delete, data: [confirm: "Are you sure?"] %></span>
        </td>
      </tr>
    <% end %>
    """
  end
end
