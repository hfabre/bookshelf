class BooksController < ApplicationController
  before_action :set_book, only: [ :edit, :update, :download, :destroy ]

  def index
    @books = current_user.books.includes(:authors, :serie).ordered
    @books = @books.where("title LIKE ?", "%#{params[:q]}%") if params[:q].present?
    @books = filter_books(@books)
  end

  def edit
  end

  def update
    if BookServices::UpdateAndSync.new(@book).call(book_params)
      redirect_to books_path, notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: t(".notice")
  end

  def download
    send_data @book.epub_content, filename: @book.filename, type: "application/epub+zip", disposition: "attachment"
  end

  def upload
    if params[:files].blank?
      redirect_to books_path, alert: t(".no_files")
      return
    end

    count = BookServices::CreateFromUploads.new(current_user).call(params[:files])

    if count > 0
      redirect_to books_path, notice: t(".processing", count: count)
    else
      redirect_to books_path, alert: t(".none_valid")
    end
  end

  private

  def filter_books(books)
    case params[:filter]
    when "no_serie" then books.without_serie
    when "no_author" then books.without_authors
    when "incomplete" then books.incomplete
    else books
    end
  end

  def set_book
    @book = current_user.books.find(params[:id])
  end

  def book_params
    params.require(:book).permit(
      :title, :description, :language, :date, :publisher, :serie_index, :cover, :serie_name, author_names: []
    )
  end
end
