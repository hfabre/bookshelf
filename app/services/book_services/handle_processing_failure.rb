module BookServices
  class HandleProcessingFailure
    def initialize(book)
      @book = book
    end

    def call(error)
      book.update!(processing_status: :failed, failure_message: error.message)
      Rails.logger.error "Failed to process EPUB for book #{book.id}: #{error.message}"
      DiscordNotifier.new.call(discord_message(error))
      EpubProcessingMailer.failed(book).deliver_later
    end

    private

    attr_reader :book

    def discord_message(error)
      <<~MSG.strip
        :warning: EPUB processing failed
        Book: #{book.title.presence || book.filename} (##{book.id})
        User: #{book.user.email_address}
        Reason: #{error.message}
      MSG
    end
  end
end
