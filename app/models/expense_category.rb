class ExpenseCategory < ApplicationRecord
  has_many :transaction_categories
  has_many :lockbox_transactions, through: :transaction_categories

  validates :identifier, presence: true, uniqueness: true
  validates :display_name, presence: true, uniqueness: true
  validates :category_code # Should this be unique?
end
