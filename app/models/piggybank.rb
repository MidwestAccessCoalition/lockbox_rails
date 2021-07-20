class Piggybank < ApplicationRecord
  has_many :piggybank_organizations
  has_many :organizations, through: :piggybank_organizations
end