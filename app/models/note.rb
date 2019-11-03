class Note < ApplicationRecord
  belongs_to :notable, polymorphic: true
  belongs_to :user, optional: true
  validates :text, presence: true

  after_create :notify_partner, if: :should_notify_partner?

  def author
    if user
      user.name || "User #{user.id}"
    else
      "System Generated"
    end
  end

  private

  def notify_partner
    NoteMailer.with(note: self).single_note.deliver_now
  end

  def should_notify_partner?
    # Do not send email for system-generated notes (at least for now)
    !!user && notable.is_a?(SupportRequest)
  end
end
