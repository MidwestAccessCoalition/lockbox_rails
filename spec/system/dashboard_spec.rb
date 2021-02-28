require 'rails_helper'
require './lib/create_support_request'

RSpec.describe "Dashboard", type: :system do
  ENV["LOCKBOX_EMAIL"] = "lockbox@email.com"

  let!(:admin_user) { FactoryBot.create(:user) }
  let!(:lockbox_partner) do
    FactoryBot.create(:lockbox_partner, :with_active_user)
  end

  let(:submit_cash_addition) do
    click_link("View Lockbox Partner Details")
    click_link("Add cash to lockbox")
    page.all(:fillable_field, 'add_cash_amount').last.set 500
    click_button "Submit"

    click_link "Back to dashboard"
  end

  describe "when user is an admin" do
    before do
      login_as(admin_user)
      visit("/")
    end

    context "when a partner has low balance" do
      # Expect 0 balance since there are no transactions
      it "alerts for low balance without cash addition" do
        page.assert_text("#{lockbox_partner.name}'s balance of $#{lockbox_partner.balance} is below $#{LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE}. Please replenish the funds.")
      end

      it "alerts for low balance with unconfirmed cash addition" do
        submit_cash_addition

        page.assert_text("#{lockbox_partner.name}'s balance of $#{lockbox_partner.balance} is below $#{LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE}. Please replenish the funds.")
      end

      it "doesn't alert for low balance with confirmed cash addition" do
        submit_cash_addition

        lockbox_partner.lockbox_actions.last.complete!

        page.assert_no_text("#{lockbox_partner.name}'s balance of $#{lockbox_partner.balance} is below $#{LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE}. Please replenish the funds.")
      end
    end

  end

  describe "when user is a partner" do
    before do
      login_as(lockbox_partner.users.last)
      visit("/")
    end

    context "when a partner has low balance" do
      # Expect 0 balance since there are no transactions
      it "alerts for low balance without cash addition" do
        page.assert_text("Your lockbox balance is below $#{LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE}. The lockbox manager should be reaching out to you shortly. If you haven't heard from them in a few days, please email #{ENV['LOCKBOX_EMAIL']}.")
      end

      it "removes alert for low balance with confirmed cash addition" do
        lockbox_action = lockbox_partner.lockbox_actions.create!(
          eff_date: Time.zone.now,
          action_type: :add_cash,
          status: LockboxAction::PENDING
        )
        lockbox_action.lockbox_transactions.create!(
          amount_cents: 50000,
          balance_effect: LockboxTransaction::CREDIT,
          category: 'cash_addition'
        )
        visit("/")
        page.assert_text("Your lockbox balance is below $#{LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE}. The lockbox manager should be reaching out to you shortly. If you haven't heard from them in a few days, please email #{ENV['LOCKBOX_EMAIL']}.")

        click_link "Confirm Cash Addition"

        page.assert_no_text("Your lockbox balance is below $#{LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE}. The lockbox manager should be reaching out to you shortly. If you haven't heard from them in a few days, please email #{ENV['LOCKBOX_EMAIL']}.")
      end
    end

  end
end
