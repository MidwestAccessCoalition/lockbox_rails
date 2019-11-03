class NoteMailer < ApplicationMailer
  def single_note
    @note = params[:note]
    @support_request = @note.notable

    unless @support_request.is_a?(SupportRequest)
      raise ArgumentError, "This note is not associated with a support request"
    end

    subject = "A new note was added to Support Request ##{@support_request.id}"
    coordinator_emails = [@support_request.user.email, @note.user.email].uniq
    # If a coordinator creates the note, email the partner users and CC the
    # coordinator(s). If a partner user creates it, do the reverse
    to_emails, cc_emails = if @note.user.admin?
      [partner_user_emails, coordinator_emails]
    else
      [coordinator_emails, partner_user_emails]
    end

    mail(to: to_emails, subject: subject, cc: cc_emails)
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
