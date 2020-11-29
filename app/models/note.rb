class Note < ApplicationRecord
  belongs_to :notable, polymorphic: true
  belongs_to :user, optional: true
  validates :text, presence: true

  after_create :send_alerts

  validates :notable_action, inclusion: { in: %w{create update annotate} }

  scope :user_generated, -> { where.not(user_id: nil) }

  def author
    if user
      user.display_name
    else
      "System Generated"
    end
  end

  def created_at_formatted
    created_at.strftime('%B %d, %Y')
  end

  def system_generated?
    user_id.blank?
  end

  def redact!
    update!(text: SupportRequest::REDACTED)
  end

  private

  def send_alerts
    NoteMailerWorker.perform_async(id)
  end
end
