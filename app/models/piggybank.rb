class Piggybank < ApplicationRecord
  after_initialize :set_defaults

  has_many :piggybank_organizations
  has_many :organizations, through: :piggybank_organizations

  has_paper_trail

  MINIMUM_ACCEPTABLE_BALANCE = Money.new(500_00) # $500

  def set_defaults
    self.minimum_acceptable_balance_cents ||= MINIMUM_ACCEPTABLE_BALANCE.cents
  end
end