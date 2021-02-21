FactoryBot.define do
  factory :expense_category do
    display_name { Faker::Commerce.product_name }
    identifier { display_name.downcase.gsub(/[^a-z]/, "_") }
    sequence :category_code do |n|
      "6" + sprintf("%03d", n)
    end
  end
end
