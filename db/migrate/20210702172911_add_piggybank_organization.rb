class AddPiggybankOrganization < ActiveRecord::Migration[6.1]
  def change
    create_table :piggybank_organizations do |t|
      t.references :piggybank, foreign_key: true
      t.references :organization, foreign_key: true
      t.string :role

      t.timestamps
    end
  end
end
