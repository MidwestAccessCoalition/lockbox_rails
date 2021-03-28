class AddExpenseCategoryIdToLockboxTransactions < ActiveRecord::Migration[6.1]
  def change
    add_reference :lockbox_transactions, :expense_category, foreign_key: true
  end
end
