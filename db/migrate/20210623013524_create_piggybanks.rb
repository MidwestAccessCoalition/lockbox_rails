class CreatePiggybanks < ActiveRecord::Migration[6.1]
  def change
    create_table :piggybanks do |t|
      t.string :name
      t.integer :minimum_acceptable_balance_cents
      t.string :description

      t.timestamps
    end
  end
end
