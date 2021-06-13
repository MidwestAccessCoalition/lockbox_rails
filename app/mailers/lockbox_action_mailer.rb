class LockboxActionMailer < ApplicationMailer
  def add_cash_email
    @lockbox_partner = params[:lockbox_partner]
    @lockbox_action = params[:lockbox_action]

    email_addresses = @lockbox_partner.users.active.pluck(:email)
    return if email_addresses.empty?

    mail(to: email_addresses, subject: 'Incoming Lockbox Cash in the Mail')
  end
end
