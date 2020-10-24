require 'rails_helper'

RSpec.describe "LockboxPartner show page", type: :system do
  let!(:lockbox_partner) { create(:lockbox_partner, :active) }
  let!(:user) { create(:user) }
  before do
    # 1 completed add cash action already exists
    19.times { create(:support_request, :pending, lockbox_partner: lockbox_partner) }
    login_as(user, :scope => :user)
  end

  it "has pagination" do
    visit("/lockbox_partners/1")
    page.assert_selector(".support-request-container ul.pagination", count: 0)
    create(:support_request, :pending, lockbox_partner: lockbox_partner)
    visit("/lockbox_partners/1")
    page.assert_selector(".support-request-container ul.pagination", count: 1)
    page.assert_selector(".support-request-container .lockbox-activity tr.pending", count: 20)
    click_link("2")
    page.assert_selector(".support-request-container .lockbox-activity tr.completed", count: 1)
  end
end