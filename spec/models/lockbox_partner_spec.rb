require 'rails_helper'
require './lib/add_cash_to_lockbox'

describe LockboxPartner, type: :model do
  it { is_expected.to have_many(:users) }
  it { is_expected.to have_many(:lockbox_actions) }

  def add_cash(partner, date)
    LockboxAction.create!(
      action_type:     LockboxAction::ADD_CASH,
      status:          LockboxAction::PENDING,
      eff_date:        date,
      lockbox_partner: partner
    ).tap do |action|
      action.lockbox_transactions.create!(
        amount_cents: 1000_00,
        balance_effect: LockboxTransaction::CREDIT,
        expense_category: FactoryBot.create(:expense_category)
      )
    end
  end


  def pending_request_on(partner, date, amount_breakdown, request)
    partner.lockbox_actions.create!(
      action_type: LockboxAction::SUPPORT_CLIENT,
      status:      LockboxAction::PENDING,
      support_request: request,
      eff_date:    date
    ).tap do |lb_action|
      amount_breakdown.each do |amt_cents|
        lb_action.lockbox_transactions.create!(
          amount_cents: amt_cents,
          balance_effect: LockboxTransaction::DEBIT,
          expense_category: FactoryBot.create(:expense_category)
        )
      end
    end
  end

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

  describe '#longstanding_pending_cash_addition?' do
    let(:partner) { FactoryBot.create(:lockbox_partner) }

    context 'with a longstanding pending cash addition' do
      let!(:cash_addition) { add_cash(partner, 4.days.ago) }
      it 'is true' do
        expect(partner.longstanding_pending_cash_addition?).to be_truthy
      end
    end

    context 'with a recent pending cash addition' do
      let!(:cash_addition) { add_cash(partner, 2.days.ago) }
      it 'is false' do
        expect(partner.longstanding_pending_cash_addition?).not_to be_truthy
      end
    end
  end

  describe '#pending_cash_addition_age' do
    let(:partner) { FactoryBot.create(:lockbox_partner) }

    context 'without a pending cash addition' do
      it 'is zero' do
        expect(partner.pending_cash_addition_age).to eq(0)
      end
    end

    context 'with a pending cash addition' do
      let!(:cash_addition) { add_cash(partner, 2.days.ago) }
      it 'counts the correct number of days' do
        expect(partner.pending_cash_addition_age).to eq(2)
      end
    end
  end

  describe '#recently_completed_first_cash_addition?' do
    let(:partner) { FactoryBot.create(:lockbox_partner, :with_active_user) }

    context 'when there is no completed cash addition' do
      it 'is false' do
        expect(partner.recently_completed_first_cash_addition?).not_to be_truthy
      end
    end

    context 'when there is a completed cash addition' do
      let(:cash_addition) { add_cash(partner, 3.days.ago) }

      it 'is true if the cash addition is recently complete' do
        cash_addition.complete!
        expect(partner.recently_completed_first_cash_addition?).to be_truthy
      end

      it 'is false if the cash addition is not recently complete' do
        Timecop.freeze(49.hours.ago) {
          cash_addition.complete!
        }
        expect(partner.recently_completed_first_cash_addition?).not_to be_truthy
      end

      context 'when there has been a support request filed' do
        let(:request) { FactoryBot.create(:support_request, lockbox_partner: partner, user: partner.users.first) }
        let(:support) { pending_request_on(partner, Date.yesterday, [10_00], request) }

        it 'is false even if the cash addition is recently complete' do
          cash_addition.complete!
          support
          expect(partner.recently_completed_first_cash_addition?).not_to be_truthy
        end
      end
    end
  end

  describe 'with scope' do
    let!(:partner_1) { FactoryBot.create(:lockbox_partner) } # no active users or cash additions
    let!(:partner_2) { FactoryBot.create(:lockbox_partner) } # active users, no cash additions
    let!(:partner_3) { FactoryBot.create(:lockbox_partner) } # no active users, a completed cash addition - not sure this is something we would actually see in production?
    let!(:partner_4) { FactoryBot.create(:lockbox_partner) } # active users and cash additions

    let!(:active_users_partner_2) { FactoryBot.create_list(:user, 2, :partner_user, lockbox_partner: partner_2) }
    let!(:active_users_partner_4) { FactoryBot.create_list(:user, 2, :partner_user, lockbox_partner: partner_4) }

    let!(:cash_additions_partner_3) { FactoryBot.create_list(:lockbox_action, 2, :completed, :add_cash, lockbox_partner: partner_3) }
    let!(:cash_additions_partner_4) { FactoryBot.create_list(:lockbox_action, 2, :completed, :add_cash, lockbox_partner: partner_4) }

    context '#with_active_user' do
      it 'includes only the partners with an active user, and does not duplicate them' do
        expect(LockboxPartner.with_active_user).to match_array([partner_2, partner_4])
      end
    end

    context '#with_initial_cash' do
      it 'includes only the partners with a completed cash addition, and does not duplicate them' do
        expect(LockboxPartner.with_initial_cash).to match_array([partner_3, partner_4])
      end
    end

    context '#active' do
      it 'includes only the partner with a completed cash addition and an active user, and does not duplicate it' do
        expect(LockboxPartner.active).to match_array([partner_4])
      end
    end
  end

  describe '#balance' do
    let(:lockbox)    { FactoryBot.create(:lockbox_partner, :with_active_user) }
    let!(:request)    { FactoryBot.create(:support_request, lockbox_partner: lockbox, user: lockbox.users.first) }
    let(:start_date) { Date.current - 2.months }

    context 'have only added cash but no support requests yet' do
      let(:add_cash_action) { add_cash(lockbox, start_date) }

      context 'when the add cash is pending' do
        it 'returns 0' do
          expect(lockbox.balance).to eq(Money.zero)
          expect(lockbox.balance(exclude_pending: true)).to eq(Money.zero)
        end
      end

      context 'when the add cash action is completed' do
        before { add_cash_action.complete! }

        it 'returns the amount of the initial cashbox deposit' do
          expect(lockbox.balance).to eq(1000.to_money)
          expect(lockbox.balance(exclude_pending: true)).to eq(1000.to_money)
        end
      end
    end

    context 'add cash, multiple pending & completed actions' do
      before do
        add_cash(lockbox, start_date).complete!
        pending_request_on(lockbox, start_date + 1.week,  [20_00, 50_00], request).complete!
        pending_request_on(lockbox, start_date + 2.weeks, [30_00, 20_00, 15_00], request).complete!
        pending_request_on(lockbox, start_date + 3.weeks, [100_00], request).complete!
        pending_request_on(lockbox, Date.current - 1.week, [30_00], request)
        pending_request_on(lockbox, Date.current + 3.days, [45_00, 15_00, 10_00], request)
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
        add_cash(lockbox, start_date).complete!
        pending_request_on(lockbox, start_date + 1.week,  [20_00, 50_00], request).complete!
        pending_request_on(lockbox, start_date + 2.weeks, [30_00, 20_00, 15_00], request).complete!
        pending_request_on(lockbox, start_date + 3.weeks, [100_00], request).complete!
        pending_request_on(lockbox, start_date + 4.weeks, [75_00, 20_00], request).cancel!
        pending_request_on(lockbox, Date.current - 2.weeks, [85_00, 10_00], request).complete!
        pending_request_on(lockbox, Date.current - 10.days, [100_00], request).complete!
        pending_request_on(lockbox, Date.current - 1.week, [30_00], request).cancel!
        pending_request_on(lockbox, Date.current + 3.days, [45_00, 15_00, 10_00], request)
        pending_request_on(lockbox, Date.current + 5.days, [50_00, 15_00], request)
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
        add_cash(lockbox, start_date).complete!
        pending_request_on(lockbox, start_date + 1.week,  [20_00, 50_00], request).complete!
        pending_request_on(lockbox, start_date + 2.weeks, [30_00, 20_00, 15_00], request).complete!
        pending_request_on(lockbox, start_date + 3.weeks, [100_00], request).complete!
        pending_request_on(lockbox, start_date + 4.weeks, [75_00, 20_00], request).cancel!
        pending_request_on(lockbox, Date.current - 2.weeks, [85_00, 10_00], request).complete!
        pending_request_on(lockbox, Date.current - 10.days, [100_00], request).complete!
        pending_request_on(lockbox, Date.current - 1.week, [30_00], request).cancel!
        add_cash(lockbox, Date.yesterday).complete!
        pending_request_on(lockbox, Date.current + 3.days, [45_00, 15_00, 10_00], request)
        pending_request_on(lockbox, Date.current + 5.days, [50_00, 15_00], request)
      end

      it 'returns the correct balance -- $1435' do
        expect(lockbox.balance(exclude_pending: false)).to eq(1435.to_money)
      end

      context 'excluding pending transactions' do
        it 'returns the correct balance -- $1570' do
          expect(lockbox.balance(exclude_pending: true)).to eq(1570.to_money)
        end
      end
    end

    context 'With transactions on the current date' do
      before do
        add_cash(lockbox, start_date).complete!
        pending_request_on(lockbox, start_date + 1.week,  [20_00, 50_00], request).complete!
        pending_request_on(lockbox, start_date + 2.weeks, [30_00, 20_00, 15_00], request).complete!
        pending_request_on(lockbox, start_date + 3.weeks, [100_00], request).complete!
        pending_request_on(lockbox, start_date + 4.weeks, [75_00, 20_00], request).cancel!
        pending_request_on(lockbox, Date.current - 2.weeks, [85_00, 10_00], request).complete!
        pending_request_on(lockbox, Date.current - 10.days, [100_00], request).complete!
        pending_request_on(lockbox, Date.current - 1.week, [30_00], request).cancel!
        add_cash(lockbox, Date.yesterday)
        pending_request_on(lockbox, Date.current, [10_00, 30_00], request)
        pending_request_on(lockbox, Date.current, [35_00, 45_00], request).complete!
        pending_request_on(lockbox, Date.current, [70_00, 50_00, 30_00], request).cancel!
        pending_request_on(lockbox, Date.current + 3.days, [45_00, 15_00, 10_00], request)
        pending_request_on(lockbox, Date.current + 5.days, [50_00, 15_00], request)
      end

      it 'returns the correct balance -- $1315' do
        expect(lockbox.balance(exclude_pending: false)).to eq(315.to_money)
      end

      context 'excluding pending transactions' do
        it 'returns the correct balance -- $490' do
          expect(lockbox.balance(exclude_pending: true)).to eq(490.to_money)
        end
      end
    end
  end

  describe '#relevant_transactions_for_balance' do
    let(:partner_1) { FactoryBot.create(:lockbox_partner, :with_active_user) }
    let(:partner_2) { FactoryBot.create(:lockbox_partner, :with_active_user) }

    let(:user_1)    { FactoryBot.create(:user, lockbox_partner: partner_1) }
    let(:user_2)    { FactoryBot.create(:user, lockbox_partner: partner_2) }
    let!(:request_1) { FactoryBot.create(:support_request, lockbox_partner: partner_1, user: user_1) }
    let!(:request_2) { FactoryBot.create(:support_request, lockbox_partner: partner_2, user: user_2) }

    let!(:pending_add_cash)                { add_cash(partner_1, Date.yesterday) }
    let!(:completed_add_cash)              { add_cash(partner_1, Date.yesterday).tap{|a| a.complete!} }
    let!(:diff_partner_completed_add_cash) { add_cash(partner_2, Date.yesterday).tap{|a| a.complete!} }

    let!(:canceled_support)                { pending_request_on(partner_1, Date.yesterday, [10_00], request_1).tap{|a| a.cancel!} }
    let!(:pending_support)                 { pending_request_on(partner_1, Date.yesterday, [10_00], request_1) }
    let!(:diff_partner_pending_support)    { pending_request_on(partner_2, Date.yesterday, [10_00], request_2) }
    let!(:completed_support)               { pending_request_on(partner_1, Date.yesterday, [10_00], request_1).tap{|a| a.complete!} }
    let!(:diff_partner_completed_support)  { pending_request_on(partner_2, Date.yesterday, [10_00], request_2).tap{|a| a.complete!} }

    it 'returns pending and completed transactions for that lockbox partner' do
      expected_results = [
        completed_add_cash.lockbox_transactions,
        pending_support.lockbox_transactions,
        completed_support.lockbox_transactions
      ].flatten
      expect(partner_1.relevant_transactions_for_balance).to match(expected_results)
    end

    context 'when exclude_pending: true' do
      it 'returns only completed transactions for that lockbox partner' do
        expected_results = [
          completed_add_cash.lockbox_transactions,
          completed_support.lockbox_transactions
        ].flatten
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

      # We're initializing this in before blocks rather than calling #let!
      # because the latter approach caused state to persist between example
      # groups, causing order-dependent test failures where Timecop is used
      let(:reconciliation_action) do
        create(
          :lockbox_action,
          :reconciliation,
          lockbox_partner: lockbox_partner,
          eff_date: reconciliation_date
        )
      end

      context 'when the lockbox was last reconciled within the reconciliation interval' do
        before { reconciliation_action }

        let(:reconciliation_date) do
          (LockboxPartner::RECONCILIATION_INTERVAL - 1).days.ago
        end

        it { is_expected.to be false }
      end

      context 'when the lockbox was last reconciled outside the reconciliation interval' do
        before { reconciliation_action }

        let(:reconciliation_date) do
          LockboxPartner::RECONCILIATION_INTERVAL.days.ago
        end

        it { is_expected.to be true }
      end

      context 'when the date is different in CST and UTC' do
        before do
          Timecop.freeze(Time.local(2020, 2, 23, 23, 0, 0)) # 11 PM CST
        end

        context 'when the lockbox was last reconciled within the reconciliation interval' do
          before { reconciliation_action }

          let(:reconciliation_date) do
            (LockboxPartner::RECONCILIATION_INTERVAL - 1).days.ago
          end

          it { is_expected.to be false }
        end

        context 'when the lockbox was last reconciled outside the reconciliation interval' do
          before { reconciliation_action }

          let(:reconciliation_date) do
            LockboxPartner::RECONCILIATION_INTERVAL.days.ago
          end

          it { is_expected.to be true }
        end
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

  describe '#reconciliation_severely_overdue?' do
    subject { lockbox_partner.reconciliation_severely_overdue? }

    let(:lockbox_partner) { create(:lockbox_partner, :active) }
    let(:reconciliation_interval) { LockboxPartner::RECONCILIATION_INTERVAL }
    let(:days_until_overdue_notification) { LockboxPartner::DAYS_UNTIL_OVERDUE_RECONCILIATION_NOTIFICATION }

    before(:example) do
      create(
        :lockbox_action,
        :reconciliation,
        lockbox_partner: lockbox_partner,
        eff_date: reconciliation_date
      )
    end

    context 'when the lockbox was last reconciled within the reconciliation interval' do
      let(:reconciliation_date) { reconciliation_interval.days.ago - 1}
      it { is_expected.to be false }
    end

    context 'when the lockbox reconciliation is needed but no further time has elapsed' do
      let(:reconciliation_date) { reconciliation_interval.days.ago }
      it { is_expected.to be false }
    end

    context 'when the lockbox was last reconciled long enough ago to necessitate a notification' do
      let(:reconciliation_date) { (reconciliation_interval + days_until_overdue_notification).days.ago }
      it { is_expected.to be true }
    end
  end

  describe 'low_balance?' do
    it 'is true when the balance is below $300' do
      lockbox_partner = FactoryBot.create(:lockbox_partner)

      low_amount = LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE - Money.new(100)
      AddCashToLockbox.call!(lockbox_partner: lockbox_partner, eff_date: 1.day.ago, amount: low_amount).complete!
      expect(lockbox_partner).to be_low_balance

      AddCashToLockbox.call!(lockbox_partner: lockbox_partner, eff_date: 1.day.ago, amount: Money.new(100)).complete!
      expect(lockbox_partner).not_to be_low_balance
    end
  end
end
