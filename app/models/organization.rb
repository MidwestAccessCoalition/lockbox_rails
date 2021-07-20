class Organization < ApplicationRecord
  has_many :users
  has_many :piggybank_organizations
  has_many :piggybanks, through: :piggybank_organizations

  validates :name, presence: true
  validates :street_address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true, format: { with: /[0-9]{5}/ }
  validates :phone_number, presence: true, format: { with: /[0-9]{10}/ }

  has_paper_trail
end