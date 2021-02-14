class CreateTransactionCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :transaction_categories do |t|
      t.references :lockbox_transaction, null: false, foreign_key: true
      t.references :expense_category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
