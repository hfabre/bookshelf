class SeriesController < ApplicationController
  before_action :set_serie, only: [ :show, :edit, :update, :download ]
  before_action :require_admin, only: [ :edit, :update ]

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
    books = @serie.books.order(:serie_index, :title)
    result = ZipGeneratorService.new.call(books, @serie.name)

    if result[:success]
      send_data result[:zip_data],
                filename: result[:filename],
                type: "application/zip",
                disposition: "attachment"
    else
      redirect_to @serie, alert: result[:error]
    end
  end

  private

  def set_serie
    @serie = Serie.for_user(current_user).find(params[:id])
  end

  def serie_params
    params.require(:serie).permit(:name, :rating, :completion_state, :reading_state)
  end
end
