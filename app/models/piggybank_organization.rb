class PiggybankOrganization < ApplicationRecord
  belongs_to :piggybank
  belongs_to :organization

  has_paper_trail
end