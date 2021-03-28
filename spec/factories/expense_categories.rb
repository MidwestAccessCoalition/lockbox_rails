FactoryBot.define do
  factory :expense_category do
    # TODO figure out why this is generating non-unique display names
    display_name { Faker::Commerce.product_name }
    identifier { display_name.downcase.gsub(/[^a-z]/, "_") }
    sequence :category_code do |n|
      "6" + sprintf("%03d", n)
    end
  end
end
