module BookServices
  class SyncFromEpub
    def initialize(book, user = nil)
      @book = book
      @user = user || Current.user
    end

    def call
      epub = book.epub
      repair_container!(epub)
      metadata = epub.mt_hash
      title = metadata[:title].presence || book.filename.gsub(".epub", "")

      authors = find_or_create_authors(metadata[:authors])
      serie = find_or_create_by_name(@user.series, (metadata[:serie].presence || title).strip)
      cover_bytes = epub.cover_bytes

      save_book!(
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

    # Some archives are zipped from the book's folder instead of its contents, so
    # the container/opf live under a wrapper directory and no container sits at
    # the zip root. Rebuild a root container pointing at the discovered opf and
    # persist the repaired archive so later reads work normally.
    def repair_container!(epub)
      return unless epub.failure_reason == "BsEpub::ContainerMissing"

      epub.create_container!
      book.update!(epub_content: epub.current_buffer.string) if epub.failure_reason.nil?
    end

    # An imported serie_index that collides with another book in the same serie
    # must not fail the whole import (split volumes sharing a number, bad metadata,
    # or two concurrent imports racing for the same index). Only that specific
    # conflict is recovered from — anything else propagates.
    def save_book!(attributes)
      book.update!(attributes)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
      raise unless serie_index_conflict?(e)

      book.update!(attributes.merge(serie_index: nil))
    end

    def serie_index_conflict?(error)
      case error
      when ActiveRecord::RecordInvalid then error.record.errors.of_kind?(:serie_index, :taken)
      when ActiveRecord::RecordNotUnique then error.message.include?("serie_index")
      end
    end

    def find_or_create_authors(authors)
      Array(authors).filter_map { |name| name&.strip.presence }.uniq.map do |name|
        find_or_create_by_name(@user.authors, name)
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
