class Piggybank < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :piggybank_organizations
  has_many :organizations, through: :piggybank_organizations
end