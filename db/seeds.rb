User.destroy_all
LockboxPartner.destroy_all
SupportRequest.destroy_all
LockboxTransaction.destroy_all
LockboxAction.destroy_all

mac_user = User.where(email: 'cats@test.com').first_or_create!(
  name: 'Sally Snake',
  password: 'password1234',
  confirmed_at: Time.current,
  role: User::ADMIN
)

LOCKBOX_PARTNERS = [
  ['Cats Clinic', 'fluffy@catsclinic.com'],
  ['Owl Health Associates', 'swoop@owls.com'],
  ['Healthy Sloths', 'yawny@sloths.com'],
  ['Dogs Clinic', 'floof@dogs.com'],
]

LOCKBOX_PARTNERS.map do |partner_name, partner_user_email|
  lockbox_partner = LockboxPartner.where(name: partner_name).first_or_create!(
    street_address: Faker::Address.street_address,
    city: Faker::Address.city,
    state: Faker::Address.state_abbr,
    zip_code: Faker::Address.zip_code,
    phone_number: (2..9).to_a.sample.to_s + Faker::Base.numerify('#########')
  )

  User.where(email: partner_user_email).first_or_create!(
    lockbox_partner: lockbox_partner,
    password: 'heytherefancypants4321',
    confirmed_at: Time.current,
    role: User::PARTNER
  )

  User.where(email: Faker::Internet.email).first_or_create!(
    lockbox_partner: lockbox_partner,
    password: 'heytherefancypants4321',
    confirmed_at: Time.current,
    role: User::PARTNER
  )

  lockbox_partner.lockbox_actions.create!(
    eff_date: Date.current - 1.week,
    action_type: LockboxAction::ADD_CASH,
    status: LockboxAction::COMPLETED
  ).tap do |action|
    action.lockbox_transactions.create!(
      amount_cents: 1000_00,
      balance_effect: LockboxTransaction::CREDIT,
      category: LockboxTransaction::CASH_ADDITION
    )
  end

  3.times do |n|
    display_name = Faker::Commerce.product_name
    ExpenseCategory.create!(
      display_name: display_name,
      identifier: display_name.downcase.gsub(/[^a-z]/, "_"),
      category_code: "6" + sprintf("%03d", n)
    )
  end

  5.times do
    support_request = SupportRequest.create!(
      client_ref_id: Faker::Alphanumeric.alpha(number: 10),
      name_or_alias: [Faker::Name.first_name, Faker::Name.initials(number: 2)].sample,
      lockbox_partner: lockbox_partner,
      user: User.first
    ).tap do |sup_req|
      action = LockboxAction.create!(
        eff_date: Date.current + (1..10).to_a.sample.days,
        action_type: LockboxAction::SUPPORT_CLIENT,
        lockbox_partner: lockbox_partner,
        support_request_id: sup_req.id
      )

      categories = LockboxTransaction::SELECTABLE_EXPENSE_CATEGORIES.sample((1..3).to_a.sample)
      categories.each do |category|
        action.lockbox_transactions.create!(
          amount_cents: (1_00..60_00).to_a.sample,
          balance_effect: LockboxTransaction::DEBIT,
          category: LockboxTransaction::EXPENSE,
          expense_category: ExpenseCategory.all.sample
        )
      end

      3.times do
        sup_req.notes.create(user: User.last, text: Faker::Lorem.sentence)
      end
    end
  end
end

has_many_actions = LockboxPartner.where(name: LOCKBOX_PARTNERS.last.first).first
20.times do
  support_request = SupportRequest.create!(
    client_ref_id: Faker::Alphanumeric.alpha(number: 10),
    name_or_alias: [Faker::Name.first_name, Faker::Name.initials(number: 2)].sample,
    lockbox_partner: has_many_actions,
    user: User.first
  ).tap do |sup_req|
    action = LockboxAction.create!(
      eff_date: Date.current + (1..10).to_a.sample.days,
      action_type: LockboxAction::SUPPORT_CLIENT,
      lockbox_partner: has_many_actions,
      support_request_id: sup_req.id
    )

    categories = ExpenseCategory.all
    categories.each do |category|
      action.lockbox_transactions.create!(
        amount_cents: (1_00..60_00).to_a.sample,
        balance_effect: LockboxTransaction::DEBIT,
        category: LockboxTransaction::EXPENSE,
        expense_category: category
      )
    end
  end
end
