require "bs_epub/epub"
require "zip"
require "marcel"

class EpubProcessorJob < ApplicationJob
  queue_as :default

  def perform(book_id)
    book = Book.find(book_id)
    book.update!(processing_status: :processing)

    begin
      BookServices::SyncFromEpub.new(book).call
      book.update!(processing_status: :completed)
      Rails.logger.info "Successfully processed EPUB: #{book.title}"
    rescue => e
      Rails.logger.error "Failed to process EPUB for book #{book.id}: #{e.message}"
      book.update!(processing_status: :failed)
      raise e
    end
  end
end
