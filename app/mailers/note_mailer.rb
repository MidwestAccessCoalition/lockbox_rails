class NoteMailer < ApplicationMailer

  def self.deliver_note_creation_alerts(note)
    recipients(note).each do |email|
      NoteMailer.with(note: note, address: email).note_creation_alert.deliver_now
    end
  end

  def note_creation_alert
    @note = params[:note]

    if @note.notable_type == "SupportRequest" && @note.notable_action == "create"
      support_request_creation_alert
    elsif @note.system_generated?
      system_annotation_alert
    else
      user_annotation_alert
    end
  end

  def system_annotation_alert
    subject = "New System note on #{@note.notable_type.titleize} ##{@note.notable_id}"
    mail(to: params[:address], subject: subject, template_name: "system_annotation_alert")
  end

  def user_annotation_alert
    subject = "New note from #{@note.author} on #{@note.notable_type.titleize} ##{@note.notable_id}"
    mail(to: params[:address], subject: subject, template_name: "user_annotation_alert")
  end

  def support_request_creation_alert
    @support_request = @note.notable

    urgency_flag_prefix = if @support_request.urgency_flag.present?
      "#{@support_request.urgency_flag} - "
    else
      ""
    end

    subject = "#{urgency_flag_prefix}MAC Cash Box Withdrawal Request"
    mail(to: params[:address], subject: subject, template_name: "support_request_creation_alert")
  end

  private

  def self.recipients(note)
    # MAC users only get emailed about manual notes
    # MAC users don't get emailed about notes they wrote
    users = User.admin.active
    users -= [note.user]

    # Partner users get emailed about all notes
    users.concat(note.notable.try(:lockbox_partner).try(:users) || [])

    users.collect(&:email)
  end
end
