class Organization < ApplicationRecord
  has_many :users
  has_many :piggybanks, through: :piggybank_organizations
end