class SupportRequestMailer < ApplicationMailer
  def creation_alert
    @support_request = params[:support_request]
    urgency_flag_prefix = if @support_request.urgency_flag.present?
      "#{@support_request.urgency_flag} - "
    else
      ""
    end

    subject = "#{urgency_flag_prefix}MAC Cash Box Withdrawal Request"

    mail(
      to: partner_user_emails,
      subject: subject,
      cc: @support_request.user.email
    )
  end

  private

  def partner_user_emails
    @partner_user_emails ||= @support_request
      .lockbox_partner
      .users
      .confirmed
      .pluck(:email)
    if @partner_user_emails.empty?
      raise ArgumentError, "Attempted to alert users for "\
        "#{@support_request.lockbox_partner.name}, but none exist"
    end
    @partner_user_emails
  end
end
