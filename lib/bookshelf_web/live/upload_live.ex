defmodule BookshelfWeb.UploadLive do
  use BookshelfWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bookshelf.PubSubs.ImportBook.subscribe()
    end

      {:ok,
        socket
        |> assign(:running_tasks, MapSet.new())
        |> allow_upload(:book_files, accept: ~w(.epub), progress: &handle_progress/3, max_entries: 1000, auto_upload: true),
      layout: false}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:import, {:ok, {:ok, _results}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:import, {:exit, reason}, socket) do
    IO.inspect reason
    # TODO: notify failure. Flash ?
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_job, filename}, socket) do
    running_tasks = Map.get(socket.assigns, :running_tasks)
    {:noreply, assign(socket, running_tasks: MapSet.put(running_tasks, filename))}
  end

  @impl true
  def handle_info({:end_of_job, filename}, socket) do
    running_tasks = Map.get(socket.assigns, :running_tasks)
    {:noreply, assign(socket, running_tasks: MapSet.delete(running_tasks, filename))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form id="upload-form" phx-change="validate">
        <label class="inline-block rounded border border-gray-400 bg-gray-400 px-4 py-1 text-sm font-medium text-white hover:bg-transparent hover:text-gray-400 focus:outline-none focus:ring active:text-gray-300">
          Upload
          <.live_file_input upload={@uploads.book_files} class="hidden" />
        </label>
      </form>
    </div>

    <div class="mt-2 border-t border-gray-100">
      <%= if MapSet.size(@running_tasks) > 0 do %>
        <span>Running tasks: <%= MapSet.size(@running_tasks) %></span>
      <% else %>
        <span>No running tasks</span>
      <% end %>
    </div>
    """
  end

  defp handle_progress(:book_files, entry, socket) do
    filename = entry.client_name
    Bookshelf.PubSubs.ImportBook.notify_new_job(filename)

    if entry.done? do
      consume_uploaded_entry(socket, entry, fn %{} = meta ->
        IO.puts("Consuming entry #{meta.path}")
        content = File.read!(meta.path)
        IO.puts("Registering worker for #{filename}")
        Task.Supervisor.start_child(Bookshelf.ImportBookSupervisor, fn ->
          Bookshelf.Workers.ImportBook.run(filename, content)
        end)
      end)
    end

    {:noreply, socket}
  end
end
