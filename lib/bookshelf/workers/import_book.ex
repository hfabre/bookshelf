defmodule Bookshelf.Workers.ImportBook do
  def run(filename, zip_content) do
    IO.puts("Processing #{filename}")

    temp_dir = Briefly.create!(type: :directory)
    new_path = Path.join(temp_dir, filename)

    try do
      File.write!(new_path, zip_content)

      # zip_content = File.read!(path)
      {result, _} = System.cmd(Application.app_dir(:bookshelf, ["priv", "bs_epub", "bin", "get_metadata"]), [new_path])
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
        filename: filename,
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
        book_title: filename,
        log: Exception.message(e),
        stacktrace: Exception.format_stacktrace(__STACKTRACE__)
        })

        reraise e, __STACKTRACE__
    after
      Bookshelf.PubSubs.ImportBook.notify_end_of_job(filename)
    end
  end
end
