class PiggybankOrganization < ApplicationRecord
  belongs_to :piggybank
  belongs_to :organization
end