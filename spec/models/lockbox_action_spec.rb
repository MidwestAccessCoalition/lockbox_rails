require 'rails_helper'

describe LockboxAction, type: :model do
  it { is_expected.to belong_to(:lockbox_partner) }
  it { is_expected.to belong_to(:support_request).optional }
  it { is_expected.to have_many(:lockbox_transactions) }
  it { is_expected.to have_many(:notes) }
  it { is_expected.to have_one(:tracking_info) }

  describe '.create_with_transactions' do
    context 'some unknown status' do
      it 'raises an error' do
        action = LockboxAction.new(status: 'oops')
        action.valid?
        expect(action.errors.messages[:status]).to include('is not included in the list')
      end
    end

    context 'some unknown action type' do
      it 'raises an error' do
        action = LockboxAction.new(action_type: 'whoops')
        action.valid?
        expect(action.errors.messages[:action_type]).to include('is not included in the list')
      end
    end

    context 'add_cash' do
      # given an amount and a date
      # creates a corresponding credit txn
      # no category
    end

    context 'reconcile' do
      # given an amount and a date
      # compares amount to balance
      # creates an adjustment if amount counted != amount expected
      # (credit if amount counted > amount expected)
      # (debit if amount counted < amount expected)
    end

    context 'support_client' do
      # given an amount, a date, and a cost breakdown
      # cost breakdown is an array of hashes containing amount & category
      # may create multiple debit txns depending on items in cost breakdown
    end
  end

  describe '#amount' do
    subject do
      FactoryBot.create(:lockbox_action, :support_client).tap do |action|
        action.lockbox_transactions.create(
          amount_cents: 20_00,
          balance_effect: LockboxTransaction::DEBIT,
          category: LockboxTransaction::EXPENSE,
          expense_category_id: FactoryBot.create(:expense_category).id
        )
        action.lockbox_transactions.create(
          amount_cents: 20_00,
          balance_effect: LockboxTransaction::DEBIT,
          category: LockboxTransaction::EXPENSE,
          expense_category_id: FactoryBot.create(:expense_category).id
        )
      end
    end

    it "sums the action's transactions" do
      expect(subject.amount).to eq(40.to_money)
    end

    context 'when no transactions are present' do
      before do
        subject.lockbox_transactions.each(&:destroy)
        subject.reload
      end

      it "return zero" do
        expect(subject.amount).to eq(Money.zero)
      end
    end

    context 'when action is in canceled status' do
      before do
        subject.cancel!
      end

      it "returns zero and creates a version record" do
        expect(subject.amount).to eq(Money.zero)
        expect(subject.versions.count).to eq 2
        expect(subject.versions.last.changeset['status']).to eq ["pending", "canceled"]
      end
    end
  end

  describe '#pending?' do
    subject { FactoryBot.create(:lockbox_action) }

    it { is_expected.to be_pending }
  end

  describe '#completed?' do
    subject { FactoryBot.create(:lockbox_action, :completed) }

    it { is_expected.to be_completed }
  end

  describe '#canceled?' do
    subject { FactoryBot.create(:lockbox_action, :canceled) }

    it { is_expected.to be_canceled }
  end

  describe '#cancel!' do
    subject { FactoryBot.create(:lockbox_action) }

    it 'updates the status to canceled' do
      expect { subject.cancel! }.to change{ subject.status }.from('pending').to('canceled')
    end
  end

  describe '#complete!' do
    subject { FactoryBot.create(:lockbox_action) }

    it 'updates the status to canceled' do
      expect { subject.complete! }.to change{ subject.status }.from('pending').to('completed')
    end
  end

  describe '#set_default_status' do
    let(:partner) { FactoryBot.create(:lockbox_partner) }
    let(:action) do
      LockboxAction.create(
        lockbox_partner: partner,
        eff_date: Date.current,
        action_type: LockboxAction::ADD_CASH,
        status: status
      )
    end

    context 'When a lockbox action is created with a nil status' do
      let(:status) { nil }
      it "saves it with a pending status" do
        expect(action).to be_pending
      end
    end

    context 'When a lockbox action is created with a status' do
      let(:status) { LockboxAction::COMPLETED }
      it "uses the given status" do
        expect(action).to be_completed
      end
    end
  end
end
