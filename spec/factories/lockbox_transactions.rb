FactoryBot.define do
  factory :lockbox_transaction do
    balance_effect   { 'debit' }
    amount_cents     { 100_00 }
    expense_category { create(:expense_category) }
    lockbox_action   { build(:lockbox_action) }

    trait :for_add_cash do
      balance_effect { LockboxTransaction::CREDIT }
    end
  end
end
