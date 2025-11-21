class AuthorsController < ApplicationController
  def index
    @authors = current_user.authors.ordered
    @authors = @authors.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?

    respond_to do |format|
      format.html
      format.json { render json: @authors.map { |a| { id: a.id, name: a.name } } }
    end
  end
end
