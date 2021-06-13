class User < ApplicationRecord
  belongs_to :lockbox_partner, optional: true
  has_many :support_requests
  has_many :invitees, class_name: "User", foreign_key: 'invited_by_id'
  belongs_to :inviter, class_name: "User",  optional: true, foreign_key: 'invited_by_id'

  # all but :omniauthable
  devise(
    :authy_authenticatable, 
    :authy_lockable,
    :confirmable,
    :database_authenticatable,
    :lockable, 
    :recoverable, 
    :registerable, 
    :rememberable,
    :timeoutable,
    :trackable, 
    :validatable,
  )

  ROLES = [
    ADMIN  = 'admin',
    PARTNER = 'partner'
  ].freeze

  validates :role, presence: true, inclusion: { in: ROLES }

  # for grepability:
  # scope :admin
  # scope :partner
  ROLES.each do |role|
    scope role, -> { where(role: role) }
  end

  PRIORITY_TIME_ZONES = [
    ActiveSupport::TimeZone["Eastern Time (US & Canada)"],
    ActiveSupport::TimeZone["Central Time (US & Canada)"],
    ActiveSupport::TimeZone["Mountain Time (US & Canada)"],
    ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
  ].freeze

  scope :confirmed, -> { where.not(confirmed_at: nil) }

  def authy_enabled
    # This method overwrites devise-authy functionality to always return false
    # if the MFA feature is not live. This method should be deleted after
    # MFA goes live.
    !!ENV['AUTHY_MFA_ENABLED'] ? super : false
  end

  def admin?
    role == ADMIN
  end

  def partner?
    role == PARTNER
  end

  def has_signed_in?
    !!last_sign_in_at
  end

  def status
    return "pending" if confirmed_at.nil?
    return "locked" if locked_at.present?
    return "active"
  end

  def available_action_text
    return "Resend Invite" if status == "pending"
    return "Unlock Account" if status == "locked"
    return "Lock Account" if status == "active"
  end

  def display_name
    self.name || "User #{id}"
  end

  def self.get_admin_emails
    User.admin.pluck(:email).join(",")
  end

  private

  def password_required?
    confirmed? ? super : false
  end
end
