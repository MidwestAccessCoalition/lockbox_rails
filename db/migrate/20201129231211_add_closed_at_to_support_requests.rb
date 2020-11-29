class AddClosedAtToSupportRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :support_requests, :closed_at, :datetime
  end
end
