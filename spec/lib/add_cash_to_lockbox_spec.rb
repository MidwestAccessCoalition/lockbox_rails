require 'rails_helper'
require './lib/add_cash_to_lockbox'

describe AddCashToLockbox do
  let(:lockbox_partner) { FactoryBot.create(:lockbox_partner, :with_active_user) }
  let!(:locked_user) { create(:user, role: "partner", lockbox_partner: lockbox_partner, locked_at: Time.now) }
  let(:eff_date) { 1.day.from_now.to_date }
  let(:params) do
    {
      lockbox_partner: lockbox_partner,
      eff_date: eff_date,
      amount: amount
    }
  end
  let(:amount) { Money.new(1000) }

  def add_cash
    AddCashToLockbox.call(params)
  end

  context 'when the params are valid' do
    it "creates one lockbox action" do
      expect{add_cash}.to change(LockboxAction, :count).by(1)
    end

    it "creates the lockbox action with the correct attributes" do
      lockbox_action = add_cash.value
      expect(lockbox_action.lockbox_partner_id).to eq(lockbox_partner.id)
      expect(lockbox_action.action_type).to eq(LockboxAction::ADD_CASH)
      expect(lockbox_action.status).to eq(LockboxAction::PENDING)
    end

    it "creates one lockbox transaction" do
      expect{add_cash}.to change(LockboxTransaction, :count).by(1)
    end

    it "creates the lockbox transaction with the correct attributes" do
      lockbox_transaction = add_cash.value.lockbox_transactions.first
      expect(lockbox_transaction.eff_date).to eq(eff_date)
      expect(lockbox_transaction.amount).to eq(amount)
      expect(lockbox_transaction.balance_effect).to eq(LockboxTransaction::CREDIT)
    end

    it "does not create lockbox_infos without any tracking info passed in" do
      expect{add_cash}.to change(TrackingInfo, :count).by(0)
    end

    it "emails the lockbox partner's active users" do
      expect{ add_cash }.to change{ ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq('Incoming Lockbox Cash in the Mail')
      expect(mail.body).to include(amount)
      expect(mail.to.to_s).not_to include(locked_user.email)
    end

    it "succeeds" do
      expect(add_cash.succeeded?).to be true
    end
  end

  context "when tracking number is passed in" do
    let(:params) {{
      lockbox_partner: lockbox_partner,
      eff_date: eff_date,
      amount: amount,
      tracking_number: 12345
    }}

    it "saves tracking info" do
      expect{add_cash}.to change(TrackingInfo, :count).by(1)
      expect(TrackingInfo.order(:created_at).last.tracking_number).to eq ("12345")
      expect(TrackingInfo.order(:created_at).last.delivery_method).to eq nil
    end


    it "emails the tracking info" do
      expect{ add_cash }.to change{ ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq('Incoming Lockbox Cash in the Mail')
      expect(mail.body).to include(amount)
      expect(mail.body).to include("12345")
    end
  end

  context "when delivery method is passed in" do
    let(:params) {{
      lockbox_partner: lockbox_partner,
      eff_date: eff_date,
      amount: amount,
      delivery_method: "Mail Today"
    }}

    it "saves tracking info" do
      expect{add_cash}.to change(TrackingInfo, :count).by(1)
      expect(TrackingInfo.order(:created_at).last.tracking_number).to eq nil
      expect(TrackingInfo.order(:created_at).last.delivery_method).to eq "Mail Today"
    end

    it "emails the tracking info" do
      expect{ add_cash }.to change{ ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq('Incoming Lockbox Cash in the Mail')
      expect(mail.body).to include(amount)
      expect(mail.body).to include("Mail Today")
    end
  end

  context "when delivery method and tracking number are passed in" do
    let(:params) {{
      lockbox_partner: lockbox_partner,
      eff_date: eff_date,
      amount: amount,
      tracking_number: 123456,
      delivery_method: "Mail Today"
    }}

    it "saves tracking info" do
      expect{add_cash}.to change(TrackingInfo, :count).by(1)
      expect(TrackingInfo.order(:created_at).last.tracking_number).to eq "123456"
      expect(TrackingInfo.order(:created_at).last.delivery_method).to eq "Mail Today"
    end

    it "emails the tracking info" do
      expect{ add_cash }.to change{ ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq('Incoming Lockbox Cash in the Mail')
      expect(mail.body).to include(amount)
      expect(mail.body).to include("123456")
      expect(mail.body).to include("Mail Today")
    end
  end

  context "when delivery method and tracking number are passed in but they're empty" do
    let(:params) {{
      lockbox_partner: lockbox_partner,
      eff_date: eff_date,
      amount: amount,
      tracking_number: "",
      delivery_method: ""
    }}

    it "does not save tracking info" do
      expect{add_cash}.to change(TrackingInfo, :count).by(0)
    end
  end

  context 'when the params are invalid' do
    let(:amount) { "this is not a number" }

    it "does not create a lockbox action" do
      expect{add_cash}.not_to change(LockboxAction, :count)
    end

    it "does not create a lockbox transaction" do
      expect{add_cash}.not_to change(LockboxTransaction, :count)
    end

    it "does not email the lockbox partner's users" do
      expect{ add_cash }.not_to change{ ActionMailer::Base.deliveries.count }
    end

    it "fails" do
      expect(add_cash.succeeded?).to be false
    end
  end
end
