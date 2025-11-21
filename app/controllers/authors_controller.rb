class AuthorsController < ApplicationController
  before_action :set_author, only: [:show, :edit, :update, :download]

  def index
    @authors = current_user.authors.includes(books: :serie).ordered
    @authors = @authors.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?

    respond_to do |format|
      format.html
      format.json { render json: @authors.map { |a| { id: a.id, name: a.name } } }
    end
  end

  def show
    @books = @author.books.includes(:serie, :authors).ordered
  end

  def edit
  end

  def update
    if @author.update(author_params)
      redirect_to @author, notice: "Author was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def download
    require 'zip'

    books = @author.books

    if books.empty?
      redirect_to @author, alert: "No books found for this author."
      return
    end

    zip_data = Zip::OutputStream.write_buffer do |zip|
      books.each do |book|
        if book.epub_content.present?
          zip.put_next_entry(book.filename)
          zip.write(book.epub_content)
        end
      end
    end

    send_data zip_data.string,
              filename: "#{@author.name.parameterize}-books.zip",
              type: "application/zip",
              disposition: "attachment"
  end

  private

  def set_author
    @author = current_user.authors.find(params[:id])
  end

  def author_params
    params.require(:author).permit(:name)
  end
end
