class AuthorsController < ApplicationController
  include Paginated
  include LibraryScoped

  before_action :set_library_owner, only: [ :index, :show ]
  before_action :set_author, only: [ :edit, :update, :download, :merge, :perform_merge ]
  before_action :require_admin, only: [ :edit, :update ]

  def index
    @authors = library_owner.authors.ordered
    @authors = @authors.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?

    respond_to do |format|
      format.html do
        @authors = paginate(@authors)
        @previews = BookServices::IndexPreviews.for_authors(@authors)
      end
      format.json { render json: @authors.map { |a| { id: a.id, name: a.name } } }
    end
  end

  def show
    @author = library_owner.authors.find(params[:id])
    @books = @author.books.includes(:serie, :authors).ordered
  end

  def edit
  end

  def update
    if @author.update(author_params)
      redirect_to @author, notice: t(".notice")
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

  def merge
    @similar_authors = @author.similar
  end

  def perform_merge
    author_ids = params[:author_ids]&.map(&:to_i) || []
    authors_to_merge = current_user.authors.where(id: author_ids)

    if authors_to_merge.empty?
      redirect_to merge_author_path(@author), alert: t(".no_selection")
      return
    end

    result = AuthorServices::MergeService.new(@author).call(authors_to_merge)

    if result[:success]
      redirect_to authors_path, notice: result[:message]
    else
      redirect_to merge_author_path(@author), alert: result[:error]
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
