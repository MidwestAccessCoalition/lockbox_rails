class Users::DeviseAuthyController < Devise::DeviseAuthyController
  layout "application"

  protected
  
  def after_authy_enabled_path_for(resource)
  end

  def after_authy_verified_path_for(resource)
    if resource.sign_in_count > 1
      root_path
    else
      onboarding_success_path
    end
  end

  def after_authy_disabled_path_for(resource)
    edit_user_registration_path
  end

  def invalid_resource_path
    super
  end
end