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
      redirect_to safe_return_to, notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    orphan_candidates = [ @book.serie, *@book.authors ]
    @book.destroy
    BookServices::CleanupOrphans.call(orphan_candidates)
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

    result = BookServices::CreateFromUploads.new(current_user).call(params[:files])

    notice = t(".processing", count: result[:created]) if result[:created].positive?
    alert =
      if result[:skipped].any?
        t(".skipped", filenames: result[:skipped].join(", "))
      elsif result[:created].zero?
        t(".none_valid")
      end

    redirect_to books_path, notice: notice, alert: alert
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

  # Only accept local paths to avoid open redirects.
  def safe_return_to
    to = params[:return_to].to_s
    to.start_with?("/") && !to.start_with?("//") ? to : books_path
  end

  def book_params
    params.require(:book).permit(
      :title, :description, :language, :date, :publisher, :serie_index, :cover, :serie_name, author_names: []
    )
  end
end
