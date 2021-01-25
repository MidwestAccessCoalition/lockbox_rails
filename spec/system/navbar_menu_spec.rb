require 'rails_helper'

RSpec.describe "Navbar menu", type: :system do
  let!(:admin_user) { FactoryBot.create(:user, role: User::ADMIN) }
  let!(:lockbox_partner) { create(:lockbox_partner, :active) }
  let!(:partner_user) { FactoryBot.create(:user, role: User::PARTNER, lockbox_partner: lockbox_partner) }

  describe "when user is an admin" do
    before do
      login_as(admin_user)
      visit("/")
    end

    context "navbar control button" do
      it "is present" do
        page.assert_selector("#navbar-control", visible: :visible, count: 1)
      end
    end

    context "navbar drawer" do
      it "is not visible on page load" do
        page.assert_no_selector("#navbar-drawer")
      end
    end

    context "clicking navbar control button" do
      it "opens navbar when closed" do
        click_button("navbar-control")
        page.assert_selector("#navbar-drawer", visible: :visible, count: 1)
      end

      it "closes navbar when opened" do
        click_button("navbar-control")
        page.assert_selector("#navbar-drawer", visible: :visible, count: 1)
        click_button("navbar-control")
        page.assert_no_selector("#navbar-drawer")
      end

      it "does not have secondary nav tabs" do
        click_button("navbar-control")
        page.assert_no_text("Add cash to lockbox")
        page.assert_no_text("Manage lockbox partner")
      end

      it "has secondary nav tabs" do
        visit("/lockbox_partners/#{lockbox_partner.id}")
        click_button("navbar-control")
        page.assert_text("Add cash to lockbox")
        page.assert_text("Manage lockbox partner")
      end
    end
  end

  describe "when user is a partner" do
    before do
      login_as(partner_user)
      visit("/")
      click_button("navbar-control")
    end

    context "when the drawer is open" do
      it "clicking a secondary nav tab closes the drawer" do
        click_link("All Activity")
        page.assert_no_selector("#navbar-drawer")
      end

      it "clicking multiple secondary nav tabs doesn't cause the drawer to flicker" do
        click_link("All Activity")
        click_link("Action Needed")
        page.assert_no_selector("#navbar-drawer")
        click_link("All Activity")
        page.assert_no_selector("#navbar-drawer")
      end
    end
  end

end
