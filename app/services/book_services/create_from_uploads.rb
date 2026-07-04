module BookServices
  class CreateFromUploads
    # EPUBs are zip containers; marcel reports either the specific epub type or the
    # generic zip type depending on how the archive was produced.
    EPUB_MIME_TYPES = [ "application/epub+zip", "application/zip" ].freeze

    def initialize(user)
      @user = user
    end

    def call(files)
      epub_files(files).each_with_object({ created: 0, skipped: [] }) do |file, result|
        if create_book(file)
          result[:created] += 1
        else
          result[:skipped] << file.original_filename
        end
      end
    end

    private

    attr_reader :user

    def epub_files(files)
      Array(files).compact.select { |file| epub?(file) }
    end

    def epub?(file)
      return false unless file.respond_to?(:read) && file.respond_to?(:original_filename)
      return false unless file.original_filename.to_s.downcase.end_with?(".epub")

      EPUB_MIME_TYPES.include?(Marcel::MimeType.for(file))
    end

    def create_book(file)
      file.rewind

      book = user.books.create(
        title: file.original_filename.gsub(".epub", ""),
        filename: file.original_filename,
        epub_content: file.read,
        processing_status: :pending
      )

      return false unless book.persisted?

      job = EpubProcessorJob.perform_later(book.id, user.id)
      book.update!(job_id: job.job_id)
      true
    end
  end
end
