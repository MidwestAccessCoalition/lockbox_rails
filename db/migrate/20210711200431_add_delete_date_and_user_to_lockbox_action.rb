class AddDeleteDateAndUserToLockboxAction < ActiveRecord::Migration[6.0]
  def change
    add_column :lockbox_actions, :delete_date, :datetime
    add_column :lockbox_actions, :delete_user, :bigint
  end
end
