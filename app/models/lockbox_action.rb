# frozen_string_literal: true

class LockboxAction < ApplicationRecord
  belongs_to :lockbox_partner
  belongs_to :support_request, optional: true
  has_many :lockbox_transactions, dependent: :destroy
  has_many :notes, as: :notable
  has_one :tracking_info

  accepts_nested_attributes_for :lockbox_transactions, reject_if: :all_blank,
    allow_destroy: true

  validates :eff_date, presence: true
  validates :support_request_id, presence: true, if: -> { action_type == 'support_client' }
  validate :validate_partner_is_active,
    if: -> { ['support_client', 'reconcile'].include?(action_type) }

  before_validation :inherit_lockbox_partner_id

  before_validation :set_default_status
  has_paper_trail

  before_save :record_closed_at, if: :will_save_change_to_status?

  STATUSES = [
    PENDING   = 'pending',
    COMPLETED = 'completed',
    CANCELED  = 'canceled'
  ].freeze
  validates :status, inclusion: STATUSES

  EDITABLE_STATUSES = [PENDING].freeze

  CLOSED_STATUSES = [COMPLETED, CANCELED].freeze

  ACTION_TYPES = [
    ADD_CASH = 'add_cash',
    RECONCILE = 'reconcile',
    SUPPORT_CLIENT = 'support_client'
  ].freeze
  validates :action_type, inclusion: ACTION_TYPES

  scope :excluding_statuses, -> (*statuses) { where.not(status: statuses) }

  scope :pending_cash_additions,   -> { where(status: PENDING,   action_type: ADD_CASH) }
  scope :completed_cash_additions, -> { where(status: COMPLETED, action_type: ADD_CASH) }

  # action_type should correspond with ACTION_TYPES
  def self.create_with_transactions(action_type, params)
    if !ACTION_TYPES.include?(action_type)
      raise ArgumentError.new("The only Lockbox actions supported are #{ACTION_TYPES.join(',')}")
    else
      ActiveRecord::Base.transaction do
        lockbox_action = create!(
          eff_date: params[:eff_date],
          action_type: action_type,
          status: PENDING
        )

        case action_type
        when :add_cash
          lockbox_action.lockbox_transactions.create!(
            eff_date: params[:eff_date],
            amount_cents: params[:amount_cents],
            balance_effect: LockboxTransaction::CREDIT
          )
        when :reconcile
          expected_amount = lockbox_partner.expected_cash_in_box.cents
          return if expected_amount == params[:amount_cents]

          balance_effect = if expected_amount > params[:amount_cents]
            LockboxTransaction::DEBIT
          else
            LockboxTransaction::CREDIT
          end

          lockbox_action.lockbox_transactions.create!(
            eff_date: params[:eff_date],
            amount_cents: params[:amount_cents],
            balance_effect: balance_effect,
            category: LockboxTransation::ADJUSTMENT
          )
        when :support_client
          params[:cost_breakdown].each do |item|
            lockbox_action.lockbox_transactions.create!(
              eff_date:       params[:eff_date],
              amount_cents:   item[:amount_cents],
              balance_effect: LockboxTransaction::DEBIT,
              category:       item[:category]
            )
          end
        end

        lockbox_action
      end
    end
  end

  def eff_date_formatted
    eff_date.strftime('%B %d, %Y')
  end

  def amount
    return Money.zero if canceled?
    return Money.zero if lockbox_transactions.none?
    lockbox_transactions.map(&:amount).sum
  end

  def pending?
    status == PENDING
  end

  def completed?
    status == COMPLETED
  end

  def canceled?
    status == CANCELED
  end

  def editable_status?
    EDITABLE_STATUSES.include?(status)
  end

  def closed?
    CLOSED_STATUSES.include?(status)
  end

  def cancel!
    update!(status: CANCELED)
  end

  def complete!
    update!(status: COMPLETED)
  end

  def breakdown
    lockbox_transactions.map do |txn|
      { amount: txn.amount, category: txn.expense_category.display_name }
    end
  end

  def credit?
    lockbox_transactions.first&.balance_effect == LockboxTransaction::CREDIT
  end

  def debit?
    lockbox_transactions.first&.balance_effect == LockboxTransaction::DEBIT
  end

  def tracking_info_formatted
    if tracking_info.present?
      "#{tracking_info.delivery_method} #{tracking_info.tracking_number}"
    end
  end

  private

  def inherit_lockbox_partner_id
    if lockbox_partner_id.blank? && support_request&.lockbox_partner_id
      self.lockbox_partner_id = support_request.lockbox_partner_id
    end
  end

  def set_default_status
    self.status ||= PENDING
  end

  def validate_partner_is_active
    unless lockbox_partner.active?
      errors.add(:lockbox_partner, "must be active")
    end
  end

  def record_closed_at
    if closed?
      self.closed_at = DateTime.current
    else
      # Avoids an inconsistent state if a lockbox action gets "unclosed",
      # although that probably shouldn't happen
      self.closed_at = nil
    end
  end
end
