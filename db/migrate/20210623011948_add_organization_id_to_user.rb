class AddOrganizationIdToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :organization_id, :bigint
    add_index :users, :organization_id
  end
end