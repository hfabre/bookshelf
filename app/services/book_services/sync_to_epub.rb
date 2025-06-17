module BookServices
  class SyncToEpub
    def initialize(book)
      @book = book
    end

    def call
      epub = book.epub
      epub.update_mt!(metadata)
      epub.replace_cover!(cover_file.path)
      book.update!(epub_content: epub.zip.write_buffer)
    end

    private

    attr_reader :book

    def metadata
      {
        title: book.title,
        description: book.description,
        language: book.language,
        date: book.date,
        publisher: book.publisher,
        serie: book.serie.name,
        series_index: book.serie_index,
        authors: book.author_names
      }
    end

    def cover_file
      Tempfile.new([ "cover", File.extname(book.cover_filename) ]) do |file|
        file.binmode
        file.write(book.cover_bytes)
        file.rewind
        file
      end
    end
  end
end
