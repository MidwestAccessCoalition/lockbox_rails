class SupportRequest < ApplicationRecord
  belongs_to :lockbox_partner
  belongs_to :user
  has_many :lockbox_actions
  has_many :notes, as: :notable

  validates :client_ref_id, presence: true
  validates :name_or_alias, presence: true
  validates :user, presence: true
  validates :lockbox_partner, presence: true

  # Sometimes the UUID will already have been created elsewhere, and sometimes not
  before_validation :populate_client_ref_id

  private

  def populate_client_ref_id
    self.client_ref_id = SecureRandom.uuid if client_ref_id.blank?
  end
end
