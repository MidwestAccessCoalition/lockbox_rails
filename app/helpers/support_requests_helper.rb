module SupportRequestsHelper
  def expense_category_select_options
    ExpenseCategory.order(:display_name).pluck(:display_name, :id)
  end

  def lockbox_partner_select_options
    LockboxPartner.order(:name).pluck(:name, :id)
  end

  def active_lockbox_partner_select_options
    LockboxPartner.active.order(:name).group("lockbox_partners.id").pluck(:name, :id)
  end

  def empty_lockbox_action
    @lockbox_action = LockboxAction.new()
    @lockbox_action.lockbox_transactions = (0..2).map { LockboxTransaction.new }
    @lockbox_action
  end
end
