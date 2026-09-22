class ApplicationController < ActionController::Base
  include Pagy::Backend

  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Please log in to continue."
    end
  end

  def require_role(*roles)
    unless logged_in? && roles.map(&:to_s).include?(current_user.role)
      redirect_to root_path, alert: "You are not authorized to view that page."
    end
  end

  def render_not_found
    respond_to do |format|
      format.json { render json: { error: "Not found" }, status: :not_found }
      format.html { render plain: "404 Not Found", status: :not_found }
    end
  end
end
