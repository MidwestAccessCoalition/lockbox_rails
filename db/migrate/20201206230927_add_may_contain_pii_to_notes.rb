class AddMayContainPiiToNotes < ActiveRecord::Migration[6.0]
  def change
    add_column :notes, :may_contain_pii, :boolean, default: false
  end
end
