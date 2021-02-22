# frozen_string_literal: true

class LockboxTransaction < ApplicationRecord
  monetize :amount_cents

  belongs_to :lockbox_action
  belongs_to :expense_category

  validates :amount_cents, numericality: { greater_than: 0 }
  has_paper_trail

  before_validation :default_values

  BALANCE_EFFECTS = [
    DEBIT  = 'debit',
    CREDIT = 'credit'
  ].freeze
  validates :balance_effect, inclusion: BALANCE_EFFECTS

  QUICKBOOKS_EXPENSE_CATEGORIES = [
    # These match the categories used in QuickBooks
    BUS_TRAVEL                  = 'bus_travel',
    RIDESHARE_TRAVEL            = 'rideshare_travel',
    TRAIN_TRAVEL                = 'train_travel',
    AIR_TRAVEL                  = 'air_travel',
    GAS_REIMBURSEMENTS          = 'gas_reimbursements',
    OTHER_CLIENT_TRAVEL_PARKING = 'other_client_travel:_parking',
    ACCOMMODATIONS              = 'accommodations',
    FOOD                        = 'food',
    PRESCRIPTIONS               = 'prescriptions',
    CHILDCARE_REIMBURSEMENTS    = 'childcare_reimbursements',
    OTHER_CLIENT_SUPPLIES       = 'other_client_supplies',
    PROCEDURES                  = 'procedures',
  ].freeze

  INTERNAL_EXPENSE_CATEGORIES = [
    # Used for internal Lockbox purposes
    ADJUSTMENT    = 'adjustment',
    CASH_ADDITION = 'cash_addition',
  ].freeze

  LEGACY_EXPENSE_CATEGORIES = [
    # These may appear on old records, but should not be set on any new records
    GAS                 = 'gas',
    PARKING             = 'parking',
    TRANSIT             = 'transit',
    CHILDCARE           = 'childcare',
    MEDICINE            = 'medicine',
    HOTEL_REIMBURSEMENT = 'hotel_reimbursement',
  ].freeze

  SELECTABLE_EXPENSE_CATEGORIES = (
    QUICKBOOKS_EXPENSE_CATEGORIES + INTERNAL_EXPENSE_CATEGORIES
  ).freeze

  EXPENSE_CATEGORIES = (
    SELECTABLE_EXPENSE_CATEGORIES + LEGACY_EXPENSE_CATEGORIES
  ).freeze

  QUICKBOOKS_CATEGORY_CODES = {
    BUS_TRAVEL                  => '6001',
    TRAIN_TRAVEL                => '6002',
    RIDESHARE_TRAVEL            => '6003',
    AIR_TRAVEL                  => '6004',
    GAS_REIMBURSEMENTS          => '6005',
    OTHER_CLIENT_TRAVEL_PARKING => '6006',
    ACCOMMODATIONS              => '6007',
    FOOD                        => '6008',
    PRESCRIPTIONS               => '6009',
    CHILDCARE_REIMBURSEMENTS    => '6010',
    OTHER_CLIENT_SUPPLIES       => '6011',
    PROCEDURES                  => '6012',
  }.freeze

  def eff_date
    lockbox_action.eff_date
  end

  def quickbooks_category_code
    QUICKBOOKS_CATEGORY_CODES[category]
  end

  private

  def default_values
    self.balance_effect ||= DEBIT
  end
end
