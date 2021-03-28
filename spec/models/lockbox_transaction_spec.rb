require 'rails_helper'

describe LockboxTransaction, type: :model do
  it { is_expected.to belong_to(:lockbox_action) }

  it 'validates the category' do
    transaction = FactoryBot.build(:lockbox_transaction, category: 'whaaaat')
    transaction.valid?
    expect(transaction.errors.messages[:category]).to include('is not included in the list')
  end

  it 'validates the expense category if the transaction is an expense' do
    transaction = FactoryBot.build(
      :lockbox_transaction,
      category: LockboxTransaction::EXPENSE,
      expense_category_id: nil
    )
    transaction.valid?
    expect(transaction.errors.messages[:expense_category_id])
      .to include("can't be blank")
  end

  it 'does not validate the expense category if the transaction is not an expense' do
    transaction = FactoryBot.build(
      :lockbox_transaction,
      category: LockboxTransaction::ADJUSTMENT,
      expense_category_id: nil
    )
    transaction.valid?
    expect(transaction.errors.messages[:expense_category_id])
      .not_to include("can't be blank")
  end

  it 'does not allow an expense category to be set if the transaction is not an expense' do
    transaction = FactoryBot.build(
      :lockbox_transaction,
      category: LockboxTransaction::ADJUSTMENT,
      expense_category_id: FactoryBot.create(:expense_category).id
    )
    transaction.valid?
    expect(transaction.errors.messages[:expense_category_id])
      .to include("must be blank")
  end

  it 'validates the effect' do
    transaction = LockboxTransaction.new(balance_effect: 'magic')
    transaction.valid?
    expect(transaction.errors.messages[:balance_effect]).to include('is not included in the list')
  end
end
