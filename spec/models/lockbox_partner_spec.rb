require 'rails_helper'
require './lib/add_cash_to_lockbox'

describe LockboxPartner, type: :model do
  it { is_expected.to have_many(:users) }
  it { is_expected.to have_many(:lockbox_actions) }

  describe '#cash_addition_confirmation_pending?' do
    it "is true if the partner has a pending cash addition" do
      lp = FactoryBot.create(:lockbox_partner)
      expect(lp).not_to be_cash_addition_confirmation_pending

      AddCashToLockbox.call(lockbox_partner: lp, eff_date: Date.today, amount: 100)

      expect(lp).to be_cash_addition_confirmation_pending

      lp.lockbox_actions.pending_cash_additions.each do |la|
        la.complete!
      end

      expect(lp).not_to be_cash_addition_confirmation_pending
    end
  end

  describe '#balance' do
    let(:lockbox) { FactoryBot.create(:lockbox_partner) }

    let(:start_date) { Date.current - 2.months }

    def add_cash(date)
      LockboxAction.create!(
        action_type:     'add_cash',
        status:          'pending',
        eff_date:        start_date,
        lockbox_partner: lockbox
      ).tap do |action|
        action.lockbox_transactions.create!(
          amount_cents: 1000_00,
          balance_effect: 'credit'
        )
      end
    end

    def pending_request_on(date, amount_breakdown)
      lockbox.lockbox_actions.create!(
        action_type: 'client_support',
        status:      'pending',
        eff_date:    date,
      ).tap do |lb_action|
        amount_breakdown.each do |amt_cents|
          lb_action.lockbox_transactions.create!(
            amount_cents: amt_cents,
            balance_effect: 'debit'
          )
        end
      end
    end

    context 'have only added cash but no support requests yet' do
      before { add_cash(start_date) }

      it 'returns the amount of the initial cashbox deposit' do
        expect(lockbox.balance).to eq(1000.to_money)
      end

      context 'excluding pending' do
        it 'returns 0' do
          expect(lockbox.balance(exclude_pending: true)).to eq(Money.zero)
        end

        context 'add cash was completed' do
          before { add_cash(start_date).complete! }

          it 'returns the 1000' do
            expect(lockbox.balance(exclude_pending: true)).to eq(1000.to_money)
          end
        end
      end
    end

    context 'add cash, multiple pending & completed actions' do
      before do
        add_cash(start_date).complete!
        pending_request_on(start_date + 1.week,  [20_00, 50_00]).complete!
        pending_request_on(start_date + 2.weeks, [30_00, 20_00, 15_00]).complete!
        pending_request_on(start_date + 3.weeks, [100_00]).complete!
        pending_request_on(Date.current - 1.week, [30_00])
        pending_request_on(Date.current + 3.days, [45_00, 15_00, 10_00])
      end

      it 'returns the correct balance -- $665' do
        expect(lockbox.balance(exclude_pending: false)).to eq(665.to_money)
      end

      context 'excluding pending transactions' do
        it 'returns the correct balance -- $765' do
          expect(lockbox.balance(exclude_pending: true)).to eq(765.to_money)
        end
      end
    end

    context 'add cash, multiple pending, completed, and canceled actions' do
      before do
        add_cash(start_date).complete!
        pending_request_on(start_date + 1.week,  [20_00, 50_00]).complete!
        pending_request_on(start_date + 2.weeks, [30_00, 20_00, 15_00]).complete!
        pending_request_on(start_date + 3.weeks, [100_00]).complete!
        pending_request_on(start_date + 4.weeks, [75_00, 20_00]).cancel!
        pending_request_on(Date.current - 2.weeks, [85_00, 10_00]).complete!
        pending_request_on(Date.current - 10.days, [100_00]).complete!
        pending_request_on(Date.current - 1.week, [30_00]).cancel!
        pending_request_on(Date.current + 3.days, [45_00, 15_00, 10_00])
        pending_request_on(Date.current + 5.days, [50_00, 15_00])
      end

      it 'returns the correct balance -- $435' do
        expect(lockbox.balance(exclude_pending: false)).to eq(435.to_money)
      end

      context 'excluding pending transactions' do
        it 'returns the correct balance -- $570' do
          expect(lockbox.balance(exclude_pending: true)).to eq(570.to_money)
        end
      end
    end

    context 'multiple add cash events and a variety of transactions' do
      before do
        add_cash(start_date).complete!
        pending_request_on(start_date + 1.week,  [20_00, 50_00]).complete!
        pending_request_on(start_date + 2.weeks, [30_00, 20_00, 15_00]).complete!
        pending_request_on(start_date + 3.weeks, [100_00]).complete!
        pending_request_on(start_date + 4.weeks, [75_00, 20_00]).cancel!
        pending_request_on(Date.current - 2.weeks, [85_00, 10_00]).complete!
        pending_request_on(Date.current - 10.days, [100_00]).complete!
        pending_request_on(Date.current - 1.week, [30_00]).cancel!
        add_cash(Date.yesterday)
        pending_request_on(Date.current + 3.days, [45_00, 15_00, 10_00])
        pending_request_on(Date.current + 5.days, [50_00, 15_00])
      end

      it 'returns the correct balance -- $1435' do
        expect(lockbox.balance(exclude_pending: false)).to eq(1435.to_money)
      end

      context 'excluding pending transactions' do
        it 'returns the correct balance -- $570' do
          expect(lockbox.balance(exclude_pending: true)).to eq(570.to_money)
        end
      end
    end

    context 'With transactions on the current date' do
      before do
        add_cash(start_date).complete!
        pending_request_on(start_date + 1.week,  [20_00, 50_00]).complete!
        pending_request_on(start_date + 2.weeks, [30_00, 20_00, 15_00]).complete!
        pending_request_on(start_date + 3.weeks, [100_00]).complete!
        pending_request_on(start_date + 4.weeks, [75_00, 20_00]).cancel!
        pending_request_on(Date.current - 2.weeks, [85_00, 10_00]).complete!
        pending_request_on(Date.current - 10.days, [100_00]).complete!
        pending_request_on(Date.current - 1.week, [30_00]).cancel!
        add_cash(Date.yesterday)
        pending_request_on(Date.current, [10_00, 30_00])
        pending_request_on(Date.current, [35_00, 45_00]).complete!
        pending_request_on(Date.current, [70_00, 50_00, 30_00]).cancel!
        pending_request_on(Date.current + 3.days, [45_00, 15_00, 10_00])
        pending_request_on(Date.current + 5.days, [50_00, 15_00])
      end

      it 'returns the correct balance -- $1315' do
        expect(lockbox.balance(exclude_pending: false)).to eq(1315.to_money)
      end

      context 'excluding pending transactions' do
        it 'returns the correct balance -- $490' do
          expect(lockbox.balance(exclude_pending: true)).to eq(490.to_money)
        end
      end
    end
  end

  describe '#relevant_transactions_for_balance' do
    let(:partner_1) { FactoryBot.create(:lockbox_partner) }
    let(:partner_2) { FactoryBot.create(:lockbox_partner) }

    def create_action_txn(partner, status)
      LockboxAction.create!(
        lockbox_partner: partner,
        status: status,
        eff_date: Date.current,
        action_type: LockboxAction::ADD_CASH # using add cash b/c client support has extra validations
      ).tap do |action|
        action.lockbox_transactions.create!(
          balance_effect: LockboxTransaction::CREDIT,
          amount_cents: 1000_00
        )
      end
    end

    let!(:canceled_action_txn)     { create_action_txn(partner_1, LockboxAction::CANCELED) }
    let!(:pending_action_txn)      { create_action_txn(partner_1, LockboxAction::PENDING) }
    let!(:diff_partner_action_txn) { create_action_txn(partner_2, LockboxAction::COMPLETED) }
    let!(:completed_action_txn)    { create_action_txn(partner_1, LockboxAction::COMPLETED) }

    it 'returns pending and completed transactions for that lockbox partner' do
      expected_results = [ pending_action_txn.lockbox_transactions, completed_action_txn.lockbox_transactions ].flatten
      expect(partner_1.relevant_transactions_for_balance).to match(expected_results)
    end

    context 'when exclude_pending: true' do
      it 'returns only completed transactions for that lockbox partner' do
        expected_results = completed_action_txn.lockbox_transactions
        expect(partner_1.relevant_transactions_for_balance(exclude_pending: true)).to match(expected_results)
      end
    end
  end

  describe '#historical_actions' do
    let(:lockbox_partner_1) { FactoryBot.create(:lockbox_partner) }
    let(:lockbox_partner_2) { FactoryBot.create(:lockbox_partner) }

    context 'when no actions are present for that lockbox partner' do
      it 'returns an empty array' do
        expect(lockbox_partner_1.historical_actions).to eq([])
      end
    end

    context 'when actions are present for that lockbox partner' do
      let!(:older_lb_action) { FactoryBot.create(:lockbox_action, lockbox_partner: lockbox_partner_1, eff_date: Date.today-1.day) }
      let!(:newer_lb_action) { FactoryBot.create(:lockbox_action, lockbox_partner: lockbox_partner_1, eff_date: Date.today) }
      let!(:action_for_diff_partner) { FactoryBot.create(:lockbox_action, lockbox_partner: lockbox_partner_2, eff_date: Date.today) }

      it 'returns an array of lockbox transactions in reverse chronological order' do
        expect(lockbox_partner_1.historical_actions).to match([newer_lb_action, older_lb_action])
      end
    end
  end

  describe '#active?' do
    let(:lockbox_partner) { FactoryBot.create(:lockbox_partner) }

    before do
      allow(lockbox_partner.users).to receive_message_chain(:confirmed, :exists?)
                                  .and_return(confirmed_user_exists)
    end

    subject { lockbox_partner.active? }

    context 'when no confirmed user exists' do
      let(:confirmed_user_exists) { false }

      it { is_expected.to be false }
    end

    context 'when a confirmed user exists' do
      let(:confirmed_user_exists) { true }

      before do
        allow(lockbox_partner.lockbox_actions)
          .to receive_message_chain(:completed_cash_additions, :exists?)
          .and_return(completed_cash_addition_exists)
      end

      context 'when a completed cash addition does not exist' do
        let(:completed_cash_addition_exists) { false }

        it { is_expected.to be false }
      end

      context 'when a completed cash addition exists' do
        let(:completed_cash_addition_exists) { true }

        it { is_expected.to be true }
      end
    end
  end

  describe '#reconciliation_needed?' do
    subject { lockbox_partner.reconciliation_needed? }

    context 'when the lockbox has been reconciled before' do
      let(:lockbox_partner) { create(:lockbox_partner, :active) }

      let!(:reconciliation_action) do
        create(
          :lockbox_action,
          :reconciliation,
          lockbox_partner: lockbox_partner,
          eff_date: reconciliation_date
        )
      end

      context 'when the lockbox was last reconciled within the reconciliation interval' do
        let(:reconciliation_date) do
          (LockboxPartner::RECONCILIATION_INTERVAL - 1).days.ago
        end

        it { is_expected.to be false }
      end

      context 'when the lockbox was last reconciled outside the reconciliation interval' do
        let(:reconciliation_date) do
          LockboxPartner::RECONCILIATION_INTERVAL.days.ago
        end

        it { is_expected.to be true }
      end
    end

    context 'when the lockbox has not been reconciled before' do
      let(:lockbox_partner) do
        create(:lockbox_partner, :active)
      end

      context 'when there is a completed cash addition' do
        let!(:add_cash_action) do
          create(
            :lockbox_action,
            :add_cash,
            :completed,
            lockbox_partner: lockbox_partner,
            eff_date: add_cash_date
          )
        end

        context 'when the initial cash addition was within the reconciliation interval' do
          let(:add_cash_date) { (LockboxPartner::RECONCILIATION_INTERVAL - 1).days.ago }

          it { is_expected.to be false }
        end

        context 'when the initial cash addition was outside the reconciliation interval' do
          let(:add_cash_date) { LockboxPartner::RECONCILIATION_INTERVAL.days.ago }

          it { is_expected.to be true }
        end
      end

      context 'when there is no completed cash addition' do
        it { is_expected.to be false }
      end
    end

    context 'when the lockbox has not been saved' do
      let(:lockbox_partner) { build(:lockbox_partner) }

      it { is_expected.to be false }
    end
  end

  describe 'low_balance?' do
    it 'is true when the balance is below $300' do
      lockbox_partner = FactoryBot.create(:lockbox_partner)
      
      low_amount = LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE - Money.new(100)
      AddCashToLockbox.call(lockbox_partner: lockbox_partner, eff_date: 1.day.ago, amount: low_amount)
      expect(lockbox_partner).to be_low_balance

      AddCashToLockbox.call(lockbox_partner: lockbox_partner, eff_date: 1.day.ago, amount: Money.new(100))
      expect(lockbox_partner).not_to be_low_balance
    end
  end
end
