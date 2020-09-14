class LockboxPartner < ApplicationRecord
  has_many :users
  has_many :lockbox_actions
  has_many :support_requests, dependent: :destroy

  validates :name, presence: true
  validates :street_address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true, format: { with: /[0-9]{5}/ }
  validates :phone_number, presence: true, format: { with: /[0-9]{10}/ }
  has_paper_trail

  # Number of days since last reconciliation when clinic user will be prompted
  # to reconcile the lockbox. TODO make this configurable (issue #138)
  RECONCILIATION_INTERVAL = 30
  DAYS_UNTIL_OVERDUE_RECONCILIATION_NOTIFICATION = 7
  MINIMUM_ACCEPTABLE_BALANCE = Money.new(50000) # $500
  THRESHOLD_FOR_RECENT_INITIAL_CASH_ADDITION_IN_HOURS = 48
  THRESHOLD_LONGSTANDING_CASH_ADDITION_IN_DAYS = 3
  ZERO_BALANCE = Money.new(0)

  scope :active, -> { with_active_user.with_initial_cash }
  scope :with_active_user, -> { includes(:users).merge(User.confirmed).references(:users) }

  scope :with_initial_cash, -> do
    # returns partners that have had cash successfully added at least once
    includes(:lockbox_actions).merge(LockboxAction.completed_cash_additions).references(:lockbox_actions)
  end

  def pending_support_requests
    @pending_support_requests ||= SupportRequest.pending_for_partner(lockbox_partner_id: self.id)
  end

  def balance(exclude_pending: false)
    relevant_transactions_for_balance(exclude_pending: exclude_pending).inject(Money.zero) do |balance, action|
      case action.balance_effect
      when LockboxTransaction::CREDIT
        balance += action.amount
      when LockboxTransaction::DEBIT
        balance -= action.amount
      end
      balance
    end
  end

  def low_balance?
    balance < MINIMUM_ACCEPTABLE_BALANCE
  end

  def insufficient_funds?
    balance < ZERO_BALANCE
  end

  def cash_addition_confirmation_pending?
    lockbox_actions.pending_cash_additions.any?
  end

  def longstanding_pending_cash_addition?
    pending_cash_addition_age >= THRESHOLD_LONGSTANDING_CASH_ADDITION_IN_DAYS
  end

  def pending_cash_addition_age
    earliest_pending_cash_addition = lockbox_actions.pending_cash_additions.order(:eff_date).first
    return 0 unless earliest_pending_cash_addition
    (Date.current - earliest_pending_cash_addition.eff_date).to_i
  end

  def recently_completed_first_cash_addition?
    completed_additions = lockbox_actions.completed_cash_additions
    return false if completed_additions.none?
    return false if lockbox_actions.where(action_type: LockboxAction::SUPPORT_CLIENT).any?
    first_cash_addition_completed_at = completed_additions.order(:updated_at).first.updated_at
    hours_since_first_cash_addition_completed = (Time.current - first_cash_addition_completed_at) / 1.hour
    return false unless hours_since_first_cash_addition_completed <= THRESHOLD_FOR_RECENT_INITIAL_CASH_ADDITION_IN_HOURS
    true
  end

  def has_admin_alerts?
    recently_completed_first_cash_addition? || longstanding_pending_cash_addition?
  end

  def relevant_transactions_for_balance(exclude_pending: false)
    excluded_statuses = [ LockboxAction::CANCELED ]
    excluded_statuses << LockboxAction::PENDING if exclude_pending
    actions = LockboxAction.where(lockbox_partner: self).excluding_statuses(excluded_statuses)
    lockbox_action_ids = actions.map do |action|
      next if action.pending? && action.action_type == LockboxAction::ADD_CASH
      action.id
    end.compact
    LockboxTransaction.where(lockbox_action_id: lockbox_action_ids)
  end

  def active?
    users.confirmed.exists? && lockbox_actions.completed_cash_additions.exists?
  end

  def historical_actions
    @all_actions ||= lockbox_actions.order(eff_date: :desc)
  end

  def reconciliation_severely_overdue?
    reconciliation_over_n_days_ago?(RECONCILIATION_INTERVAL + DAYS_UNTIL_OVERDUE_RECONCILIATION_NOTIFICATION)
  end

  def reconciliation_needed?
    reconciliation_over_n_days_ago?(RECONCILIATION_INTERVAL)
  end

  def reconciliation_interval_start
    # If the lockbox has never been reconciled, start counting from the date of
    # the first cash addition
    start_date = last_reconciled_at || initial_cash_addition_date
    start_date&.to_date
  end

  private

  def reconciliation_over_n_days_ago?(num_days)
    return false unless persisted?
    return false unless !!reconciliation_interval_start
    # Cast the DateTime to a Date, since comparing a Date with a DateTime can
    # cause unexpected results when the date is different in UTC and the current
    # time zone
    reconciliation_interval_start <= num_days.days.ago.to_date
  end

  def last_reconciled_at
    lockbox_actions.where(action_type: LockboxAction::RECONCILE)
                   .order(eff_date: :desc)
                   .first
                   &.eff_date
  end

  def initial_cash_addition_date
    lockbox_actions
      .where(
        action_type: LockboxAction::ADD_CASH, status: LockboxAction::COMPLETED
      )
      .order(:eff_date)
      .first
      &.eff_date
  end
end
