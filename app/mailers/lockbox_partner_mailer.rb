class LockboxPartnerMailer < ApplicationMailer
  def insufficient_funds_alert
    @lockbox_partner = params[:lockbox_partner]
    email_address = ENV['LOCKBOX_EMAIL']
    return unless email_address.present?
    admin_emails = User.get_active_admin_emails
    subject = %Q(
      [INSUFFICIENT LOCKBOX FUNDS] #{@lockbox_partner.name} can't cover
      pending support requests
    ).strip

    mail(to: email_address, cc: admin_emails, subject: subject)
  end

  def low_balance_alert
    @lockbox_partner = params[:lockbox_partner]
    email_address = [ENV['LOW_BALANCE_ALERT_EMAIL'], ENV['LOCKBOX_EMAIL']].join(",")
    return unless email_address.present?
    admin_emails = User.get_active_admin_emails
    subject = "[LOW LOCKBOX BALANCE] #{@lockbox_partner.name} needs cash"

    mail(to: email_address, cc: admin_emails, subject: subject)
  end

  def reconciliation_completed_alert
    @lockbox_partner = params[:lockbox_partner]
    @lockbox_url = ENV['HOST']
    @lockbox_help_email = ENV['LOCKBOX_EMAIL']
    email_addresses = [ENV['LOCKBOX_EMAIL'], ENV['FINANCE_EMAIL']].select(&:present?)
    return unless email_addresses.any?
    subject = "#{@lockbox_partner.name} lockbox reconciled: $#{params[:amount]}"

    mail(to: email_addresses, subject: subject)
  end

  def reconciliation_overdue_alert
    @lockbox_partner = params[:lockbox_partner]
    @days_since_reconciliation = (Date.current - @lockbox_partner.reconciliation_interval_start).to_i
    @lockbox_url = ENV['HOST']
    @lockbox_help_email = ENV['LOCKBOX_EMAIL']
    email_address = ENV['LOCKBOX_EMAIL']
    return unless email_address.present?
    subject = "#{@lockbox_partner.name} reconciliation overdue"

    mail(to: email_address, subject: subject)
  end
end
