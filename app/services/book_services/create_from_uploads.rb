module BookServices
  class CreateFromUploads
    EPUB_CONTENT_TYPE = "application/epub+zip"

    def initialize(user)
      @user = user
    end

    def call(files)
      epub_files(files).count { |file| create_book(file) }
    end

    private

    attr_reader :user

    def epub_files(files)
      Array(files).compact.select { |file| epub?(file) }
    end

    def epub?(file)
      return false unless file.respond_to?(:content_type) && file.respond_to?(:original_filename)

      file.content_type == EPUB_CONTENT_TYPE || file.original_filename.end_with?(".epub")
    end

    def create_book(file)
      book = user.books.create(
        title: file.original_filename.gsub(".epub", ""),
        filename: file.original_filename,
        epub_content: file.read,
        processing_status: :pending
      )

      EpubProcessorJob.perform_later(book.id, user.id)
      true
    end
  end
end
