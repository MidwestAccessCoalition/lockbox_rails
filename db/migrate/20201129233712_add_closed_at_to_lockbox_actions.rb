class AddClosedAtToLockboxActions < ActiveRecord::Migration[6.0]
  def change
    add_column :lockbox_actions, :closed_at, :datetime
  end
end
