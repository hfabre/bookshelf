class SeriesController < ApplicationController
  def index
    @series = Serie.for_user(current_user).ordered
    @series = @series.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?

    respond_to do |format|
      format.html
      format.json { render json: @series.map { |s| { id: s.id, name: s.name } } }
    end
  end
end
