require 'rails_helper'

RSpec.describe "LockboxPartner show page", type: :system do
  let!(:lockbox_partner) { create(:lockbox_partner, :active) }
  let!(:user) { create(:user) }

  before { login_as(user, :scope => :user) }

  context "when there are not enough support requests to require pagination" do
    it "does not have any pagination" do
      visit("/lockbox_partners/#{lockbox_partner.id}")
      page.assert_selector(".support-request-container ul.pagination", count: 0)
    end
  end
 
  context "when there are enough support requests to require pagination" do
    before do
      20.times { create(:support_request, :pending, lockbox_partner: lockbox_partner) }
    end

    it "has pagination" do
      visit("/lockbox_partners/#{lockbox_partner.id}")
      page.assert_selector(".support-request-container ul.pagination", count: 1)
      page.assert_selector(".support-request-container .lockbox-activity")
      click_link("2")
      page.assert_selector(".support-request-container .lockbox-activity")
    end
  end
end
