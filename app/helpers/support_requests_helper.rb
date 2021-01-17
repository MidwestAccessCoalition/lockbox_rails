module SupportRequestsHelper
  def expense_category_select_options
    LockboxTransaction::SELECTABLE_EXPENSE_CATEGORIES.map { |c| [c.humanize, c] }
  end

  def lockbox_partner_select_options
    LockboxPartner.order(:name).pluck(:name, :id)
  end

  def active_lockbox_partner_select_options
    LockboxPartner.active.order(:name).pluck(:name, :id)
  end

  def empty_lockbox_action
    @lockbox_action = LockboxAction.new()
    @lockbox_action.lockbox_transactions = (0..2).map { LockboxTransaction.new }
    @lockbox_action
  end
end
