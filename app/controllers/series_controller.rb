class SeriesController < ApplicationController
  def index
    @series = current_user.series.ordered
  end
end
