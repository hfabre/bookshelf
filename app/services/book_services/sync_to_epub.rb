module BookServices
  class SyncToEpub
    def initialize(book)
      @book = book
    end

    def call
      epub = book.epub
      epub.update_mt!(metadata)
      if book.saved_change_to_cover_bytes?
        cover = cover_file # Keep reference to avoid tempfile being collected
        epub.replace_cover!(cover.path)
      end
      book.update!(epub_content: epub.current_buffer.string)
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
        serie: book.serie&.name,
        series_index: book.serie_index,
        authors: book.author_names
      }
    end

    def cover_file
      file = Tempfile.new([ "cover", BsEpub::Epub::COVER_EXT_TYPE[book.cover_type] ])
      file.binmode
      file.write(book.cover_bytes)
      file.rewind
      file
    end
  end
end
