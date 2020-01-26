class LockboxActionMailer < ApplicationMailer
  def user_confirmation_completed
    @confirmed_user = params[:confirmed_user]
    mail(to: @confirmed_user.inviter, subject: "A Lockbox User has confirmed their account")
  end
end
