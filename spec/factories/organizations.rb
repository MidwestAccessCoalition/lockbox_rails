FactoryBot.define do
  factory :organization do
    name           { "#{Faker::Creature::Bird.plausible_common_name} #{Faker::Company.suffix}" }
    phone_number   { (2..9).to_a.sample.to_s + Faker::Base.numerify('#########') }
    street_address { Faker::Address.street_address }
    city           { Faker::Address.city }
    state          { Faker::Address.state }
    zip_code       { Faker::Address.zip_code }
  end
end
