require 'rails_helper'

describe LockboxActionsController do
  let(:authorized_lockbox_partner) { create(:lockbox_partner, :active) }
  let(:unauthorized_lockbox_partner) { create(:lockbox_partner, :active) }

  let(:lockbox_action) { create(:lockbox_action, lockbox_partner: authorized_lockbox_partner, status: :pending) }

  let(:user) { create(:user, role: user_role, lockbox_partner: user_lockbox_partner) }

  describe "#update" do
    before do
      sign_in(user)
      put :update, params: {id: lockbox_action.id, lockbox_action: {status: LockboxAction::COMPLETED}}
    end

    context "when the user is an admin" do
      let(:user_role) { User::ADMIN }
      let(:user_lockbox_partner) { nil }

      it "updates the lockbox action" do
        expect(lockbox_action.reload.status).to eq(LockboxAction::COMPLETED)
      end
    end

    context "when the user belongs to the correct partner" do
      let(:user_role) { User::PARTNER }
      let(:user_lockbox_partner) { authorized_lockbox_partner }

      it "updates the lockbox action" do
        expect(lockbox_action.reload.status).to eq(LockboxAction::COMPLETED)
      end
    end

    context "when the user does not belong to the correct partner" do
      let(:user_role) { User::PARTNER }
      let(:user_lockbox_partner) { unauthorized_lockbox_partner }

      it "does not update the lockbox action" do
        expect(lockbox_action.reload.status).to eq(LockboxAction::PENDING)
      end
    end
  end
end

