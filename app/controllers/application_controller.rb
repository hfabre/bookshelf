class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern


  # Rails 8.1 bump
  before_action do
    params.permit(:authenticity_token, :commit, :utf8, :_method)
  end

  private

  def current_user
    Current.session&.user
  end
  helper_method :current_user

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user&.admin?
  end
end
