class FailedBooksController < ApplicationController
  before_action :require_admin
  before_action :set_book, only: [ :download ]

  def index
    @books = Book.failed.includes(:user).order(updated_at: :desc)
  end

  def download
    send_data @book.epub_content, filename: @book.filename, type: "application/epub+zip", disposition: "attachment"
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end
end
