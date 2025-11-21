class AuthorsController < ApplicationController
  before_action :set_author, only: [ :show, :edit, :update, :download ]
  before_action :require_admin, only: [ :edit, :update ]

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
    books = @author.books
    result = ZipGeneratorService.new.call(books, @author.name)

    if result[:success]
      send_data result[:zip_data],
                filename: result[:filename],
                type: "application/zip",
                disposition: "attachment"
    else
      redirect_to @author, alert: result[:error]
    end
  end

  private

  def set_author
    @author = current_user.authors.find(params[:id])
  end

  def author_params
    params.require(:author).permit(:name)
  end
end
