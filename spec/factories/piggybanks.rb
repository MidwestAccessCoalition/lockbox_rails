FactoryBot.define do
  factory :piggybank do
    name        { "#{Faker::Color.color_name.titleize} #{Faker::Creature::Animal.name}" }
    description { Faker::Hipster.sentence }
    minimum_acceptable_balance_cents { 500_00 }
  end
end
