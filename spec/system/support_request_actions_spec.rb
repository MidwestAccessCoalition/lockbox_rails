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
      lockbox_action_attributes: {
        eff_date: Date.current,
        lockbox_transactions_attributes:
        {
          "0":{ amount: "50", category: LockboxTransaction::PRESCRIPTIONS }
        }
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

  it "successfully change the status of a support request" do
    visit "/lockbox_partners/#{lockbox_partner.id}/support_requests/#{support_request.id}"
    click_link "Update Status"
    click_link "Completed"
    sleep(1)
    assert_selector "p.status-label", text: "Completed"
    expect(support_request.reload.status).to eq("completed")
  end

  it "successfully changes the name of a support request" do
    visit "/lockbox_partners/#{lockbox_partner.id}/support_requests/#{support_request.id}"
    click_link "Edit Support Request"
    page.all(:fillable_field, 'Client Alias').last.set "Fleafy Greens"
    click_button "Submit"
    sleep(1)
    assert_selector "h3", text: "Fleafy Greens"
  end

  it "successfully add a transaction to a support request" do
    transaction_count = support_request.reload.lockbox_action.lockbox_transactions.count
    visit "/lockbox_partners/#{lockbox_partner.id}/support_requests/#{support_request.id}"
    click_link "Edit Support Request"
    click_link "Add more values +"
    all("option[value='childcare_reimbursements']")[1].click
    page.all(:fillable_field, 'Amount').last.set 10
    click_button "Submit"
    sleep(1)
    expect(support_request.reload.lockbox_action.lockbox_transactions.count).to eq(transaction_count + 1)
    assert_selector "div.support-request-details", text: "10.00 for childcare"
  end
end
