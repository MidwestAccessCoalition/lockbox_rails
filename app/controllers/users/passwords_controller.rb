# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  layout "application", except: [:new]
  before_action :set_existing_user, only: [:edit, :update]

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  def update
    super do |resource|
      if resource.errors.empty?
        resource.update(include_name_params)
      end
    end
  end

  protected

  def after_resetting_password_path_for(resource)
    if resource.sign_in_count > 1
      super(resource)
    else
      send_user_confirmed_email if resource.inviter.present?
      # The stock devise flash message isn't needed; we display our own copy in
      # this situation
      flash.clear
      user_enable_authy_path
    end
  end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  def include_name_params
    # Devise does not use these params to update the password itself, hence
    # the absence of password and password_confirmation
    params.require(:user).permit(:name, :time_zone)
  end

  private

  def send_user_confirmed_email
    UserMailer
      .with(confirmed_user: resource)
      .user_confirmation_completed
      .deliver_now
  end

  def set_existing_user
    # Defining @existing_user is a hack to display the preset email for
    # newly created lockbox partner users, and to determine whether the user has
    # signed in before so we can display the onboarding success message.
    # The variable can't be named @user or @resource as the super call
    # will assign a newly initialized User to those variables.
    @existing_user = User.with_reset_password_token(reset_password_token)
    record_not_found unless @existing_user && @existing_user.reset_password_period_valid?
  end

  def reset_password_token
    params[:reset_password_token] || params[:user][:reset_password_token]
  end

  def record_not_found
    flash[:alert] = <<~ALERT
      Whoops! It looks like your password reset is invalid or has expired.
      Please check your email for a more recent reset link."
    ALERT
    raise ActiveRecord::RecordNotFound
  end
end
