FactoryBot.define do
  factory :piggybank do
    name { "MyString" }
    minimum_acceptable_balance_cents { 1 }
    owner_id { "" }
    description { "MyString" }
  end
end
