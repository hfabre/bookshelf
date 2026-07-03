module BookServices
  class SyncFromEpub
    def initialize(book, user = nil)
      @book = book
      @user = user || Current.user
    end

    def call
      epub = book.epub
      metadata = epub.mt_hash
      title = metadata[:title].presence || book.filename.gsub(".epub", "")

      authors = find_or_create_authors(metadata[:authors])
      serie = find_or_create_by_name(@user.series, (metadata[:serie].presence || title).strip)
      cover_bytes = epub.cover_bytes

      book.update!(
        title: title,
        description: metadata[:description],
        language: metadata[:language],
        date: parse_date(metadata[:date]),
        publisher: metadata[:publisher],
        serie: serie,
        serie_index: metadata[:serie_index]&.to_i,
        cover_bytes: cover_bytes,
        cover_type: detect_mime_type(cover_bytes, metadata[:cover_path])
      )

      book.authors = authors
    end

    private

    attr_reader :book, :user

    def find_or_create_authors(authors)
      authors.map do |author_name|
        find_or_create_by_name(@user.authors, author_name&.strip)
      end
    end

    # Concurrent jobs can race to create the same author/serie: two find nothing,
    # both insert, and the loser fails the uniqueness validation (or the DB index).
    # Recover by fetching the record the winner just created.
    def find_or_create_by_name(relation, name)
      relation.find_or_create_by!(name: name)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      relation.find_by!(name: name)
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      Date.parse(date_string.to_s)
    rescue Date::Error
      nil
    end

    def detect_mime_type(file_content, filename)
      return nil if file_content.blank?

      mime_type = Marcel::MimeType.for(file_content, name: filename)
      return mime_type if mime_type && mime_type != "application/octet-stream"

      mime_type = Marcel::MimeType.for(name: filename)
      return mime_type if mime_type && mime_type != "application/octet-stream"

      case File.extname(filename.to_s).downcase
      when ".jpg", ".jpeg" then "image/jpeg"
      when ".png" then "image/png"
      when ".gif" then "image/gif"
      when ".webp" then "image/webp"
      when ".svg" then "image/svg+xml"
      else "image/jpeg"
      end
    end
  end
end
