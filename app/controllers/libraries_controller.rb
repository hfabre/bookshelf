class LibrariesController < ApplicationController
  before_action :set_library_user, except: [:index]
  before_action :ensure_public_library, except: [:index]

  def index
    @public_users = User.where(public_library: true).order(:email_address)
  end

  def show
    redirect_to library_books_path(@library_user)
  end

  def books
    @books = @library_user.books.includes(:authors, :serie).ordered
    @books = @books.where("title LIKE ?", "%#{params[:q]}%") if params[:q].present?
    @library_owner = @library_user
    render 'books/index'
  end

  def series
    @series = @library_user.series.includes(:books).order(rating: :desc, name: :asc)
    @series = @series.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
    @library_owner = @library_user
    render 'series/index'
  end

  def authors
    @authors = @library_user.authors.includes(books: :serie).ordered
    @authors = @authors.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
    @library_owner = @library_user
    render 'authors/index'
  end

  def show_serie
    @serie = @library_user.series.find(params[:serie_id])
    @books = @serie.books.includes(:authors).order(:serie_index, :title)
    @library_owner = @library_user
    render 'series/show'
  end

  def show_author
    @author = @library_user.authors.find(params[:author_id])
    @books = @author.books.includes(:serie, :authors).ordered
    @library_owner = @library_user
    render 'authors/show'
  end

  private

  def set_library_user
    @library_user = User.find(params[:user_id])
  end

  def ensure_public_library
    unless @library_user.public_library? || @library_user == current_user
      redirect_to root_path, alert: "This library is not public."
    end
  end
end
