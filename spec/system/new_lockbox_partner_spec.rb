require 'rails_helper'
require './lib/create_support_request'

RSpec.describe "New lockbox partner form", type: :system do
  let!(:user) { FactoryBot.create(:user) }
  selector_string = "input:not([type=submit]):not([type=hidden]), select"

  before do
    login_as(user, :scope => :user)
    visit("/")
    click_link("Add a new lockbox partner")
  end

  context "on initial page load" do
    it "all inputs are present" do
      page.assert_selector(selector_string, count: 8)
    end

    it "inputs are pristine" do
      page.assert_selector(".pristine", count: 8)
    end
  end

  context "on submission of blank form" do
    it "inputs are no longer pristine" do
      click_button("Add New Partner")
      page.assert_no_selector(".pristine")
    end
  end

  context "on submission of valid form" do
    it "submission is successful" do
      fill_in "Name", with: "Jo Momma"
      fill_in "Street address", with: "123 Main Street"
      fill_in "City", with: "Chicago"
      select "Illinois", from: "State"
      fill_in "Zip code", with: "60601"
      fill_in "Phone number", with: "3123211234"
      fill_in "minimum-acceptable-balance-formatted", with: "500"
      click_button("Add New Partner")
      expect(page).to have_content("Lockbox Partner was successfully created.")
    end
  end

end
