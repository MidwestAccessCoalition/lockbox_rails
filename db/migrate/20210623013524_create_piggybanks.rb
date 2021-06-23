class CreatePiggybanks < ActiveRecord::Migration[6.1]
  def change
    create_table :piggybanks do |t|
      t.string :name
      t.integer :minimum_acceptable_balance_cents
      t.bigint :owner_id
      t.string :description

      t.timestamps
    end

    add_index :piggybanks, :owner_id
  end
end
