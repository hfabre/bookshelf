module BookServices
  # Streams every book of a user grouped into per-serie folders, loading one
  # EPUB blob at a time so memory stays flat regardless of library size.
  class LibraryBundle
    NO_SERIE_FOLDER = "No Series".freeze

    def initialize(user)
      @user = user
    end

    def any?
      @user.books.where.not(epub_content: nil).exists?
    end

    def each_entry
      ordered_rows.each do |id, filename, serie_name|
        content = @user.books.where(id: id).pick(:epub_content)
        next if content.blank?

        yield entry_path(serie_name, filename), content
      end
    end

    private

    def ordered_rows
      @user.books
           .left_joins(:serie)
           .order(Arel.sql("series.name IS NULL, series.name COLLATE NOCASE, books.serie_index, books.title"))
           .pluck(:id, :filename, "series.name")
    end

    def entry_path(serie_name, filename)
      folder = (serie_name.presence || NO_SERIE_FOLDER).tr("/", "-")
      "#{folder}/#{filename}"
    end
  end
end
