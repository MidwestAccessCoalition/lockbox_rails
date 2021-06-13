require 'rails_helper'

describe User, type: :model do
  it { is_expected.to belong_to(:lockbox_partner).optional }

  describe "#has_signed_in?" do
    let(:user) { FactoryBot.build(:user, last_sign_in_at: last_sign_in_at) }
    subject { user.has_signed_in? }

    context "when last_sign_in_at is nil" do
      let(:last_sign_in_at) { nil }

      it { is_expected.to be false }
    end

    context "when last_sign_in_at is not nil" do
      let(:last_sign_in_at) { 1.hour.ago }

      it { is_expected.to be true }
    end
  end

  describe "#status" do
    let(:user) { FactoryBot.create(:user) } # creates active user by default

    context 'when confirmed_at is nil' do
      before { user.update!(confirmed_at: nil) }
      it "status is pending" do
        expect(user.status).to eq("pending")
      end
    end

    context 'when locked_at is non-nil' do
      before { user.update!(locked_at: Time.current) }
      it "status is locked" do
        expect(user.status).to eq("locked")
      end
    end

    context 'when user has been confirmed but is not locked' do
      it "status is active" do
        expect(user.status).to eq("active")
      end
    end
  end

  describe "#available_action_text" do
    let(:user) { FactoryBot.create(:user) }

    before do
      allow(user).to receive(:status).and_return(status)
    end

    subject { user.available_action_text }

    context 'when status is pending' do
      let(:status) { 'pending' }
      it { is_expected.to eq('Resend Invite') }
    end

    context 'when status is locked' do
      let(:status) { 'locked' }
      it { is_expected.to eq('Unlock Account') }
    end

    context 'when status is active' do
      let(:status) { 'active' }
      it { is_expected.to eq('Lock Account') }
    end
  end

  describe "scopes" do
    let(:locked_user) { FactoryBot.create(:user, locked_at: Time.current) }
    let(:active_user) { FactoryBot.create(:user) }
    let(:unconfirmed_user) { FactoryBot.create(:user, confirmed_at: nil) }

    context 'when user is confirmed and not locked' do
      it "is active" do
        active_users = User.active
        expect(active_users).to include(active_user)
        expect(active_users).to_not include(locked_user)
        expect(active_users).to_not include(unconfirmed_user)
      end
    end
  end
end
