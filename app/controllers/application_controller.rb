class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit
  around_action :set_time_zone, if: -> { current_user&.time_zone }

  # Raising 404 rather than the 500 the JsonApiClient error would raise
  rescue_from ActiveRecord::RecordNotFound do
    render "errors/not_found", status: :not_found
  end

  rescue_from ActionController::RoutingError do
    render "errors/not_found", status: :not_found
  end

  rescue_from ActionController::InvalidAuthenticityToken do
    render "errors/token_error", status: :unprocessable_entity
  end

  def require_admin
    unless current_user&.admin?
      flash[:error] = "You are not authorized to access this page"
      return redirect_to root_path
    end
  end

  def require_admin_or_ownership
    return if current_user.admin?
    return if current_user.lockbox_partner == @lockbox_partner
    flash[:alert] = "You are not authorized to access this page"
    return redirect_to root_path
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def set_time_zone(&block)
    Time.use_zone(current_user.time_zone, &block)
  end
end
