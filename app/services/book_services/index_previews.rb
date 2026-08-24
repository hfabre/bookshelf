module BookServices
  # Book count and cover book for the series/authors index pages.
  #
  # These pages used to eager load the books themselves, which pulled every
  # epub_content on the page into memory just to render a cover and a count.
  class IndexPreviews
    def self.for_series(series)
      ids = series.map(&:id)

      new(
        counts: Book.where(serie_id: ids).group(:serie_id).count,
        covers: cover_books(Book.where(serie_id: ids), "books.serie_id")
      )
    end

    def self.for_authors(authors)
      ids = authors.map(&:id)
      books = Book.joins(:authors).where(authors: { id: ids })

      new(
        counts: books.group("authors.id").count,
        covers: cover_books(books, "authors.id")
      )
    end

    # One lean row per owner, no blobs: the first book that actually has a cover.
    def self.cover_books(scope, key)
      scope
        .with_cover
        .select(:id, :updated_at, "#{key} AS preview_key", "#{Book::HAS_COVER_SQL} AS has_cover")
        .order(:serie_index, :id)
        .each_with_object({}) { |book, covers| covers[book.preview_key] ||= book }
    end

    def initialize(counts:, covers:)
      @counts = counts
      @covers = covers
    end

    def book_count(record)
      @counts.fetch(record.id, 0)
    end

    def cover_book(record)
      @covers[record.id]
    end
  end
end
