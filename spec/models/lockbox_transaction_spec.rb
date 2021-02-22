require 'rails_helper'

describe LockboxTransaction, type: :model do
  it { is_expected.to belong_to(:lockbox_action) }

  # TODO BEFORE MERGE update the following tests
  it 'validates the category' do
    transaction = LockboxTransaction.new(expense_category: nil)
    transaction.valid?
    expect(transaction.errors.messages[:expense_category]).to include('must exist')
  end

  it 'validates the effect' do
    transaction = LockboxTransaction.new(balance_effect: 'magic')
    transaction.valid?
    expect(transaction.errors.messages[:balance_effect]).to include('is not included in the list')
  end
end
