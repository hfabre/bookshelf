class BooksController < ApplicationController
  before_action :set_book, only: [ :edit, :update, :download, :destroy ]

  def index
    @books = current_user.books.includes(:authors, :serie).ordered
    @books = @books.where("title LIKE ?", "%#{params[:q]}%") if params[:q].present?
  end

  def edit
  end

  def update
    if BookServices::UpdateAndSync.new(@book).call(book_params)
      redirect_to books_path, notice: "Book was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: "Book was successfully deleted."
  end

  def download
    send_data @book.epub_content, filename: @book.filename, type: "application/epub+zip", disposition: "attachment"
  end

  def upload
    if params[:files].blank?
      redirect_to books_path, alert: "Please select at least one EPUB file."
      return
    end

    count = BookServices::CreateFromUploads.new(current_user).call(params[:files])

    if count > 0
      redirect_to books_path, notice: "#{count} EPUB file(s) uploaded and are being processed."
    else
      redirect_to books_path, alert: "No valid EPUB files were found."
    end
  end

  private

  def set_book
    @book = current_user.books.find(params[:id])
  end

  def book_params
    params.require(:book).permit(
      :title, :description, :language, :date, :publisher, :serie_index, :cover, :serie_name, author_names: []
    )
  end
end
