defmodule BookshelfWeb.UploadLive do
  use BookshelfWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
      {:ok,
        socket
        |> assign(:running_tasks, 0)
        |> allow_upload(:book_files, accept: ~w(.epub), max_entries: 100),
      layout: false}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    results =
      consume_uploaded_entries(socket, :book_files, fn %{path: path}, entry ->
        IO.puts("Processing #{entry.client_name}")
        temp_dir = Briefly.create!(type: :directory)
        new_path = Path.join(temp_dir, entry.client_name)

        # Attempt to create a new hard link to the file
        case File.ln(path, new_path) do
          :ok ->
            {:ok, new_path}

          {:error, reason} ->
            IO.puts("Failed to create hard link: #{inspect(reason)}, attempting cp instead")
            File.cp!(path, new_path)
            {:ok, new_path}
        end
      end)

      lv_pid = self()

      push_task = fn ->
        send(lv_pid, {:push_task})
      end

      pop_task = fn ->
        send(lv_pid, {:pop_task})
      end

      case results do
        [path] ->
          {:noreply,
           socket
           |> start_async(:import, fn -> import_file(path, push_task: push_task, pop_task: pop_task) end)}

        results ->
          for path <- results do
            start_async(socket, :import, fn -> import_file(path, push_task: push_task, pop_task: pop_task) end)
          end

          {:noreply, socket}
      end
  end

  @impl true
  def handle_info({:push_task}, socket) do
    running_tasks = Map.get(socket.assigns, :running_tasks)
    {:noreply, assign(socket, running_tasks: running_tasks + 1)}
  end

  @impl true
  def handle_info({:pop_task}, socket) do
    running_tasks = Map.get(socket.assigns, :running_tasks)
    {:noreply, assign(socket, running_tasks: running_tasks - 1)}
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
  def render(assigns) do
    ~H"""
    <div>
      <form id="upload-form" phx-submit="save" phx-change="validate">
        <.live_file_input upload={@uploads.book_files} />
        <button type="submit">Upload</button>
      </form>
    </div>

    <div class="mt-2 border-t border-gray-100">
      <%= if @running_tasks > 0 do %>
        <span>Running tasks: <%= @running_tasks %></span>
      <% else %>
        <span>No running tasks</span>
      <% end %>
    </div>
    """
  end

  defp import_file(path, push_task: push_task, pop_task: pop_task) do
    push_task.()

    try do
      zip_content = File.read!(path)
      {result, _} = System.cmd(Application.app_dir(:bookshelf, ["priv", "bs_epub", "bin", "get_metadata"]), [path])
      metadata = Jason.decode!(result)
      IO.inspect(result)

      serie =
        if metadata["serie"] do
          {:ok, _} = Bookshelf.Repo.insert(%Bookshelf.Series.Serie{title: metadata["serie"]}, on_conflict: :nothing)
          Bookshelf.Repo.get_by(Bookshelf.Series.Serie, title: metadata["serie"])
        end

      author =
        if metadata["author"] do
          {:ok, _} = Bookshelf.Repo.insert(%Bookshelf.Authors.Author{name: metadata["author"]}, on_conflict: :nothing)
          Bookshelf.Repo.get_by(Bookshelf.Authors.Author, name: metadata["author"])
        end

      {:ok, files} = :zip.extract(zip_content, [:memory, file_list: [String.to_charlist(metadata["cover_path"])]])
      {:ok, date} = DateTimeParser.parse_date(metadata["date"])

      book = %Bookshelf.Books.Book{
        title: metadata["title"],
        language: metadata["language"],
        description: metadata["description"],
        publisher: metadata["publisher"],
        date: date,
        serie_index: metadata["serie_index"],
        filename: Path.basename(path),
        cover_filename: metadata["cover_filename"],
        cover_type: MIME.from_path(metadata["cover_filename"]),
        file: zip_content,
        cover: Base.encode64(elem(List.first(files), 1)),
        serie: serie,
        author: author
      }

      Bookshelf.Repo.insert(book)
    rescue
      e ->
        Bookshelf.ImportErrors.create_import_error(%{
        book_title: Path.basename(path),
        log: Exception.message(e),
        stacktrace: Exception.format_stacktrace(__STACKTRACE__)
        })

        reraise e, __STACKTRACE__
    after
      pop_task.()
    end
  end
end
