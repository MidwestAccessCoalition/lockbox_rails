class PagesController < ActionController::Base
  def privacy_policy
    render "privacy-policy"
  end

  def terms_of_service
    render "terms-of-service"
  end

end
