module BookServices
  class UpdateAndSync
    def initialize(book)
      @book = book
    end

    def call(params)
      @params = params

      # TODO: avoid multiple save (one there and others in sync service)
      ActiveRecord::Base.transaction do
        book.assign_attributes(book_params)
        handle_cover_upload
        book.serie = find_or_create_serie
        book.authors = find_or_create_authors
        book.save!

        SyncToEpub.new(book).call
      end

      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error "Book update failed: #{e.message}"
      false
    end

    private

    attr_reader :book, :params

    def book_params
      params.except(:serie_name, :author_names, :cover)
    end

    def handle_cover_upload
      cover_file = params[:cover]
      return unless cover_file.present?

      cover_data = cover_file.read
      mime_type = cover_file.content_type || detect_mime_type_from_filename(cover_file.original_filename)

      book.cover_bytes = cover_data
      book.cover_type = mime_type
    end

    def detect_mime_type_from_filename(filename)
      case File.extname(filename.to_s).downcase
      when ".jpg", ".jpeg"
        "image/jpeg"
      when ".png"
        "image/png"
      when ".gif"
        "image/gif"
      when ".webp"
        "image/webp"
      else
        "image/jpeg"
      end
    end

    def find_or_create_serie
      serie_name = (params[:serie_name].presence || book.title).strip

      Serie.find_or_create_by(name: serie_name)
    end

    def find_or_create_authors
      author_names = Array(params[:author_names]).map(&:strip).reject(&:blank?)

      author_names.map do |name|
        Author.find_or_create_by(name: name)
      end
    end
  end
end
