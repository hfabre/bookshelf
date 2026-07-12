require "bs_epub/epub"
require "zip"
require "marcel"

class EpubProcessorJob < ApplicationJob
  queue_as :default

  def perform(book_id, user_id)
    book = Book.find(book_id)
    user = User.find(user_id)
    book.update!(processing_status: :processing)

    begin
      BookServices::SyncFromEpub.new(book, user).call
      book.update!(processing_status: :completed)
      Rails.logger.info "Successfully processed EPUB: #{book.title}"
    rescue => e
      BookServices::HandleProcessingFailure.new(book).call(e)
      raise e
    end
  end
end
