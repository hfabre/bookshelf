class SeriesController < ApplicationController
  include ZipKit::RailsStreaming

  before_action :set_serie, only: [ :show, :edit, :update, :download, :merge, :perform_merge ]
  before_action :require_admin, only: [ :edit, :update ]

  def index
    @series = Serie.for_user(current_user).includes(:books).order(rating: :desc, name: :asc)
    @series = @series.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
    @series = filter_series(@series)

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
      redirect_to @serie, notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def download_all
    bundle = BookServices::LibraryBundle.new(current_user)

    if bundle.any?
      zip_kit_stream(filename: "#{current_user.display_name.parameterize}-library.zip") do |zip|
        bundle.each_entry do |path, content|
          zip.write_file(path) { |sink| sink << content }
        end
      end
    else
      redirect_to series_path, alert: t(".no_books")
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

  def merge
    @similar_series = @serie.similar_series
  end

  def perform_merge
    serie_ids = params[:serie_ids]&.map(&:to_i) || []
    series_to_merge = current_user.series.where(id: serie_ids)

    if series_to_merge.empty?
      redirect_to merge_serie_path(@serie), alert: t(".no_selection")
      return
    end

    result = SerieServices::MergeService.new(@serie).call(series_to_merge)

    if result[:success]
      redirect_to series_path, notice: result[:message]
    else
      redirect_to merge_serie_path(@serie), alert: result[:error]
    end
  end

  private

  def filter_series(series)
    case params[:filter]
    when "to_read" then series.to_read
    when "to_reread" then series.to_reread
    else series
    end
  end

  def set_serie
    @serie = Serie.for_user(current_user).find(params[:id])
  end

  def serie_params
    params.require(:serie).permit(:name, :rating, :completion_state, :reading_state)
  end
end
