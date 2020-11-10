class Users::DeviseAuthyController < Devise::DeviseAuthyController

  protected
  
  def after_authy_enabled_path_for(resource)
  end

  def after_authy_verified_path_for(resource)
    root_path
  end

  def after_authy_disabled_path_for(resource)
    edit_user_registration_path
  end

  def invalid_resource_path
    super
  end
end