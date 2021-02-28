require 'verbalize'

class CreateSupportRequest
  include Verbalize::Action

  # This is what params input looks like
  #
  # lockbox_partner_id: Integer
  # name_or_alias: String
  # user_id: Integer
  # client_ref_id: String
  # lockbox_action_attributes: {
  #   eff_date: Date,
  #   lockbox_transactions_attributes: [
  #     { amount: Money, category: String, distance: Integer }
  #   ]
  # }
  input :params

  attr_accessor :support_request

  class ValidationError < StandardError; end

  def call
    ActiveRecord::Base.transaction do
      self.support_request = SupportRequest.create(
        lockbox_partner_id: params[:lockbox_partner_id],
        client_ref_id: params[:client_ref_id],
        name_or_alias: params[:name_or_alias],
        urgency_flag: params[:urgency_flag],
        user_id: params[:user_id]
      )

      unless support_request.valid? && support_request.persisted?
        raise ValidationError, support_request.errors.full_messages.join(', ')
      end

      lockbox_action = LockboxAction.create(
        eff_date: params[:lockbox_action_attributes][:eff_date],
        action_type: LockboxAction::SUPPORT_CLIENT,
        status: LockboxAction::PENDING,
        lockbox_partner_id: params[:lockbox_partner_id],
        support_request: support_request
      )

      unless lockbox_action.valid? && lockbox_action.persisted?
        raise ValidationError, lockbox_action.errors.full_messages.join(', ')
      end

      unless params[:lockbox_action_attributes][:lockbox_transactions_attributes]
        raise ValidationError, "Must have at least one lockbox transaction"
      end

      params[:lockbox_action_attributes][:lockbox_transactions_attributes].values
        .reject { |lt| lt[:amount].blank? && lt[:expense_category_id].blank? }
        .each do |item|
          lockbox_transaction = lockbox_action.lockbox_transactions.create(
            amount:              item[:amount],
            distance:            item[:distance],
            balance_effect:      LockboxTransaction::DEBIT,
            category:            LockboxTransaction::EXPENSE,
            expense_category_id: item[:expense_category_id]
          )

          unless lockbox_transaction.valid? && lockbox_transaction.persisted?
            raise ValidationError, lockbox_transaction.errors.full_messages.join(', ')
          end

        unless lockbox_action.lockbox_transactions.exists?
          raise ValidationError, "Amount must be greater than $0"
        end
      end
    end

    support_request.record_creation_async
    send_applicable_balance_alerts

    support_request
  rescue CreateSupportRequest::ValidationError => err
    fail!(err.message)
  end

  def send_applicable_balance_alerts
    alert_type = if support_request.lockbox_partner.insufficient_funds?
      'insufficient_funds'
    elsif support_request.lockbox_partner.low_balance?
      'low_balance'
    else
      ''
    end

    return if alert_type.blank?

    LowBalanceAlertWorker.perform_async({
      'alert': alert_type,
      'lockbox_partner_id': support_request.lockbox_partner.id
    })
  end
end
