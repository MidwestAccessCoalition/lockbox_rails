require 'rails_helper'

RSpec.describe "Support Request Creation", type: :system do
  let!(:lockbox_partner) { FactoryBot.create(:lockbox_partner, :active, name: 'Gorillas R Us') }
  let!(:inactive_lockbox_partner) { FactoryBot.create(:lockbox_partner) }
  let!(:user)            { FactoryBot.create(:user) }

  before do
    login_as(user, :scope => :user)
  end

  it 'can file a support request from main dashboard' do
    visit "/support_requests/new"

    fill_in 'Pick-up Date', with: Date.current
    fill_in 'Client Alias',  with: 'McGee'
    fill_in 'Client Reference ID', with: 'b358250'

    page.all(:option, lockbox_partner.name).first.select_option
    page.all(:fillable_field, 'Amount').each {|e| e.set(13.37)}
    page.all(:option, 'Train travel').each(&:select_option)

    click_button "Submit"

    assert_selector "h3", text: "Support Request for"

    click_button "Add Note"

    fill_in "note_text", with: "Here's some fine & fancy note text!"

    sleep(1)
    find_button("Save Note").click
    assert_selector "td", text: "Here's some fine & fancy note text!"
  end

  it 'can file a support request from a lockbox dashboard' do
    visit "/lockbox_partners/#{lockbox_partner.id}/support_requests/new"

    assert_selector "h2", text: lockbox_partner.name

    fill_in 'Pick-up Date', with: Date.current
    fill_in 'Client Alias',  with: 'McGee'
    fill_in 'Client Reference ID', with: 'b358250'

    page.all(:fillable_field, 'Amount').each {|e| e.set(13.37)}
    page.all(:option, 'Childcare').each(&:select_option)

    click_button "Submit"

    assert_selector "h3", text: "Support Request for"

    click_button "Add Note"

    fill_in "note_text", with: "Here's some fine & fancy note text!"

    sleep(1)
    find_button("Save Note").click
    assert_selector "td", text: "Here's some fine & fancy note text!"
  end

  it 'cannot file a support request from an inactive lockbox dashboard' do
    visit "/lockbox_partners/#{inactive_lockbox_partner.id}/support_requests/new"

    assert_selector "h2", text: inactive_lockbox_partner.name
    assert_no_selector "h2", text: "New support request"
    assert_selector "p", text: "Lockbox partner not yet active"
  end

  it 'computes gas reinbursement rate' do
    visit "/support_requests/new"

    page.assert_selector('.distance-field', visible: true, count: 0)
    page.all(:option, "Gas reimbursements").first.select_option
    page.assert_selector('.distance-field', visible: true, count: 1)

    fill_in "Mileage", with: 42
    assert_selector "legend", text: "Total: $9.00"
  end
end
