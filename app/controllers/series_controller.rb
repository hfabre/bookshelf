class SeriesController < ApplicationController
  before_action :set_serie, only: [:show, :edit, :update, :download]

  def index
    @series = Serie.for_user(current_user).includes(:books).order(rating: :desc, name: :asc)
    @series = @series.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?

    respond_to do |format|
      format.html
      format.json { render json: @series.map { |s| { id: s.id, name: s.name } } }
    end
  end

  def show
    @books = @serie.books.includes(:authors).order(:serie_index, :title)
  end

  def edit
  end

  def update
    if @serie.update(serie_params)
      redirect_to @serie, notice: "Series was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def download
    require 'zip'

    books = @serie.books

    if books.empty?
      redirect_to @serie, alert: "No books found for this series."
      return
    end

    zip_data = Zip::OutputStream.write_buffer do |zip|
      books.order(:serie_index, :title).each do |book|
        if book.epub_content.present?
          zip.put_next_entry(book.filename)
          zip.write(book.epub_content)
        end
      end
    end

    send_data zip_data.string,
              filename: "#{@serie.name.parameterize}-series.zip",
              type: "application/zip",
              disposition: "attachment"
  end

  private

  def set_serie
    @serie = Serie.for_user(current_user).find(params[:id])
  end

  def serie_params
    params.require(:serie).permit(:name, :rating, :completion_state, :reading_state)
  end
end
