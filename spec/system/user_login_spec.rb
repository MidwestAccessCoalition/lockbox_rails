require 'rails_helper'

RSpec.describe "User Login Flow", type: :system do
  let!(:lockbox_partner) { FactoryBot.create(:lockbox_partner, :active, name: 'Gorillas R Us') }
  let!(:user)            { FactoryBot.create(:user, password: 'g00seONtheLOO$E!') }

  it 'a user can successfully log in' do
    visit "/users/sign_in"

    # Log in attempt with blank input
    assert_selector "h2", text: "Log in"
    fill_in "Email", with: ""
    fill_in "Password", with: ""
    click_button "Log in"

    # Log in attempt with incorrect password
    assert_selector "h2", text: "Log in"
    fill_in "Email", with: user.email
    fill_in "Password", with: "monkeybrains"
    click_button "Log in"

    # Successful log in with correct password
    assert_selector "h2", text: "Log in"
    fill_in "Email", with: user.email
    fill_in "Password", with: 'g00seONtheLOO$E!'
    click_button "Log in"
    assert_selector "h2", text: "Welcome, #{user.name}!"
  end

  it 'a user can successfully reset their password' do
    visit "/users/sign_in"
    click_link "Forgot your password?"
    assert_selector "h2", text: "Send password reset instructions"
    fill_in "Email", with: user.email
    expect { click_button "Send" }.to change{ ActionMailer::Base.deliveries.count }.by(1)
    email = ActionMailer::Base.deliveries.last
    expect(email.subject).to eq("Reset password instructions")
    expect(email.to.first).to eq(user.email)
    assert_selector "div", text: "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."
  end

end


