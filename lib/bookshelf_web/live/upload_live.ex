defmodule BookshelfWeb.UploadLive do
  use BookshelfWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
      {:ok,
        socket
        |> assign(:uploaded_files, [])
        |> allow_upload(:book_files, accept: ~w(.epub), max_entries: 100),
      layout: false}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :book_files, fn %{path: path}, entry ->
        IO.puts("Processing #{entry.client_name}")
        zip_content = File.read!(path)
        {result, _} = System.cmd("sh", ["-c", "bin/get_metadata #{path}"], cd: "tools/bs_epub")
        metadata = Jason.decode!(result)

        {:ok, _} = Bookshelf.Repo.insert(%Bookshelf.Series.Serie{title: metadata["serie"]}, on_conflict: :nothing)
        serie = Bookshelf.Repo.get_by(Bookshelf.Series.Serie, title: metadata["serie"])
        {:ok, _} = Bookshelf.Repo.insert(%Bookshelf.Authors.Author{name: metadata["author"]}, on_conflict: :nothing)
        author = Bookshelf.Repo.get_by(Bookshelf.Authors.Author, name: metadata["author"])
        {:ok, files} = :zip.extract(zip_content, [:memory, file_list: [String.to_charlist(metadata["cover_path"])]])
        {:ok, date} = DateTimeParser.parse_date(metadata["date"])

        book = %Bookshelf.Books.Book{
          title: metadata["title"],
          language: metadata["language"],
          description: metadata["description"],
          publisher: metadata["publisher"],
          date: date,
          serie_index: metadata["serie_index"],
          filename: entry.client_name,
          cover_filename: metadata["cover_filename"],
          cover_type: MIME.from_path(metadata["cover_filename"]),
          file: zip_content,
          cover: Base.encode64(elem(List.first(files), 1)),
          serie: serie,
          author: author
        }

        Bookshelf.Repo.insert(book)
        {:ok, metadata}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :book_files, ref)}
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

    <div>
      <%= for entry <- @uploads.book_files.entries do %>
        <span> <%= entry.client_name %> </span>
        <progress value={entry.progress} max="100"> <%= entry.progress %>% </progress>
        <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} aria-label="cancel">&times;</button>
      <% end %>

      <%= for err <- upload_errors(@uploads.book_files) do %>
        <p class="alert alert-danger"><%= error_to_string(err) %></p>
      <% end %>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
