FactoryBot.define do
  factory :lockbox_partner do
    name           { Faker::Company.name }
    street_address { Faker::Address.street_address }
    city           { Faker::Address.city }
    state          { Faker::Address.state }
    zip_code       { Faker::Address.zip_code }
    phone_number   { (2..9).to_a.sample.to_s + Faker::Base.numerify('#########') }
    minimum_acceptable_balance { 500_00 }

    trait :active do
      # The user needs to be confirmed, but currently the user factory does this
      # by default
      users { build_list :user, 1, :partner_user }
      lockbox_actions { build_list :lockbox_action, 1, :add_cash, :completed }
    end

    trait :with_active_user do
      users { build_list :user, 1, :partner_user }
    end
  end
end
