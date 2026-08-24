class LibrariesController < ApplicationController
  before_action :set_library_user, only: :show
  before_action :ensure_public_library, only: :show

  def index
    @public_users = User.where(public_library: true).order(:email_address)
  end

  def show
    redirect_to library_books_path(@library_user)
  end

  private

  def set_library_user
    @library_user = User.find(params[:user_id])
  end

  def ensure_public_library
    unless @library_user.public_library? || @library_user == current_user
      redirect_to root_path, alert: t("libraries.not_public")
    end
  end
end
