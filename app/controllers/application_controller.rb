class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  VIEW_MODES = %w[cards list].freeze
  DEFAULT_VIEW_MODE = "cards".freeze

  # Rails 8.1 bump
  before_action do
    params.permit(:authenticity_token, :commit, :utf8, :_method)
  end

  before_action :set_view_mode

  private

  def current_user
    Current.session&.user
  end
  helper_method :current_user

  # Card/list toggle for the browse pages: ?view= persists to a cookie so the
  # choice sticks across visits.
  def set_view_mode
    cookies[:view_mode] = { value: params[:view], expires: 1.year } if VIEW_MODES.include?(params[:view])
    @view_mode = VIEW_MODES.include?(cookies[:view_mode]) ? cookies[:view_mode] : DEFAULT_VIEW_MODE
  end

  def require_admin
    redirect_to root_path, alert: t("common.access_denied") unless current_user&.admin?
  end
end
