require 'rails_helper'

RSpec.describe "User Login Flow", type: :system do
  let!(:lockbox_partner) { FactoryBot.create(:lockbox_partner, :active, name: 'Gorillas R Us') }
  let!(:user)            { FactoryBot.create(:user, password: 'g00seONtheLOO$E!') }

  it 'a user can successfully log in' do
    visit "/users/sign_in"
    assert_selector "h2", text: "Log in"

    fill_in "Email", with: user.email
    fill_in "Password", with: "monkeybrains"
    click_button "Log in"
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

  context "With MFA enabled on the account" do
    before do
      user.update!(
        authy_enabled: true,
        authy_id: "snortygoatface"
      )
    end

    context 'When the MFA feature is enabled in the app' do
      before do
        @authy_mfa_enabled = ENV['AUTHY_MFA_ENABLED']
        ENV['AUTHY_MFA_ENABLED'] = "1"
      end

      after do
        ENV['AUTHY_MFA_ENABLED'] = @authy_mfa_enabled
      end

      it 'prompts the user to enter an MFA code' do
        visit "/users/sign_in"
        assert_selector "h2", text: "Log in"

        fill_in "Email", with: user.email
        fill_in "Password", with: 'g00seONtheLOO$E!'
        
        click_button "Log in"
        assert_selector "h2", text: "Please enter your Authy token"
      end
    end

    context 'When the MFA feature is NOT enabled in the app' do
      it 'bypasses the MFA flow' do
        visit "/users/sign_in"
        assert_selector "h2", text: "Log in"

        fill_in "Email", with: user.email
        fill_in "Password", with: 'g00seONtheLOO$E!'
        click_button "Log in"
        assert_selector "h2", text: "Welcome, #{user.name}!"
      end
    end
  end
end
