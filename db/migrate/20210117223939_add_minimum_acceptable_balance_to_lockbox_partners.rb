class AddMinimumAcceptableBalanceToLockboxPartners < ActiveRecord::Migration[6.0]
  def change
    add_column :lockbox_partners, :minimum_acceptable_balance, :integer, default: 50000
  end
end
