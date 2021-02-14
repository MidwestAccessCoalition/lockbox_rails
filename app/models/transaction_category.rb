class TransactionCategory < ApplicationRecord
  belongs_to :lockbox_transaction
  belongs_to :expense_category
end
