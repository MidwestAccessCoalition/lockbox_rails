class AddRedactedToSupportRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :support_requests, :redacted, :boolean, default: false
  end
end
