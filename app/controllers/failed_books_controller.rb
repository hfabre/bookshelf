class FailedBooksController < ApplicationController
  before_action :require_admin
  before_action :set_book, only: [ :download, :destroy ]

  def index
    @books = Book.failed.includes(:user).order(updated_at: :desc)
  end

  def download
    send_data @book.epub_content, filename: @book.filename, type: "application/epub+zip", disposition: "attachment"
  end

  def destroy
    @book.destroy
    redirect_to failed_books_path, notice: t(".notice")
  end

  def clear_all
    Book.failed.destroy_all
    redirect_to failed_books_path, notice: t(".notice")
  end

  private

  def set_book
    @book = Book.failed.find(params[:id])
  end
end
