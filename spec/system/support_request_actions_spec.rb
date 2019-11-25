require 'rails_helper'
require './lib/create_support_request'

RSpec.describe "Support Request Actions", type: :system do
  let!(:lockbox_partner) { FactoryBot.create(:lockbox_partner, :active, name: 'Gorillas R Us') }
  let!(:user)            { FactoryBot.create(:user) }
  let!(:support_request) do
    params = {
      lockbox_partner_id: lockbox_partner.id,
      name_or_alias: 'Leafy Greens',
      user_id: user.id,
      client_ref_id: 'meeps321',
      lockbox_action: {
        eff_date: Date.current,
        lockbox_transactions: [
          { amount: 50.to_money, category: LockboxTransaction::GAS }
        ]
      }
    }
    CreateSupportRequest.call!(params: params)
  end

  before do
    login_as(user, :scope => :user)
  end

  it 'successfully view, edit, and add notes to a support request' do
    visit "/lockbox_partners/#{lockbox_partner.id}/support_requests/#{support_request.id}"
    assert_selector "h3", text: "Support Request for Leafy Greens"
    click_link "Add Note"
    fill_in "note_text", with: "Here's some fine & fancy note text!"
    sleep(1)
    # Sleep for 1 second to avoid a race condition in slower environments (e.g., CircleCI)
    expect{ find_button("Save Note").click; sleep(1) }.to change{ support_request.notes.count }.by(1)
    click_link "Edit note"
    fill_in "note_text", with: "foobar"
    sleep(1)
    expect{ find_button("Save Note").click; sleep(1) }.to change { support_request.notes.last.text }.to("foobar")
  end

end
