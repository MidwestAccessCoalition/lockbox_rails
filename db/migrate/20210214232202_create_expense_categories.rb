class CreateExpenseCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :expense_categories do |t|
      t.string :identifier, index: { unique: true }
      t.string :category_code
      t.string :display_name, index: { unique: true }

      t.timestamps
    end
  end
end
