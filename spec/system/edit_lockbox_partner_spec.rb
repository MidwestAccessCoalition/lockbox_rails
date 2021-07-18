require 'rails_helper'
require './lib/create_support_request'

RSpec.describe "Edit lockbox partner", type: :system do
  let!(:user) { FactoryBot.create(:user) }
  let!(:lockbox_partner) { FactoryBot.create(:lockbox_partner) }
  selector_string = "input:not([type=submit]):not([type=hidden]), select"

  before do
    login_as(user, :scope => :user)
    visit("/lockbox_partners/#{lockbox_partner.id}")
    click_link("$#{lockbox_partner.minimum_acceptable_balance_formatted}")
  end

  context "on submission of valid form" do
    it "submission is successful" do
      fill_in "Name", with: "Jo Momma"
      fill_in "Street address", with: "123 Main Street"
      fill_in "City", with: "Chicago"
      select "Illinois", from: "State"
      fill_in "Zip code", with: "60601"
      fill_in "Phone number", with: "3123211234"
      fill_in "minimum-acceptable-balance-formatted", with: "700"
      click_button("Update Contact Info")
      expect(page).to have_content("Contact information was successfully updated.")
    end
  end

end
