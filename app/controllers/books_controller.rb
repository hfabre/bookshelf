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
    uploaded_files = params[:files]

    if uploaded_files.blank?
      redirect_to books_path, alert: "Please select at least one EPUB file."
      return
    end

    processed_count = 0

    valid_files = uploaded_files.compact.reject { |file| file.blank? || file.is_a?(String) }

    valid_files.each do |file|
      # Skip if not a valid uploaded file
      next unless file.respond_to?(:content_type) && file.respond_to?(:original_filename)
      next unless file.content_type == "application/epub+zip" || file.original_filename.end_with?(".epub")

      book = current_user.books.create(
        title: file.original_filename.gsub(".epub", ""),
        filename: file.original_filename,
        epub_content: file.read,
        processing_status: :pending
      )

      EpubProcessorJob.perform_later(book.id)
      processed_count += 1
    end

    if processed_count > 0
      redirect_to books_path, notice: "#{processed_count} EPUB file(s) uploaded and are being processed."
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
