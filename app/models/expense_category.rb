class ExpenseCategory < ApplicationRecord
  has_many :transaction_categories
  has_many :lockbox_transactions

  validates :identifier, presence: true, uniqueness: true
  validates :display_name, presence: true, uniqueness: true
end
