require 'rails_helper'

describe LockboxPartners::SupportRequestsController do
  let(:authorized_lockbox_partner) { create(:lockbox_partner, :active) }
  let(:unauthorized_lockbox_partner) { create(:lockbox_partner, :active) }

  let(:support_request) do
    req = create(:support_request, :pending, lockbox_partner: authorized_lockbox_partner)
    lockbox_transaction = create(:lockbox_transaction)
    req.lockbox_action.lockbox_transactions = [lockbox_transaction]
    req
  end

  let(:user) { create(:user, role: user_role, lockbox_partner: user_lockbox_partner) }

  describe "#new" do
    before do
      sign_in(user)
      get :new, params: { lockbox_partner_id: authorized_lockbox_partner.id }
    end

    context "when the user is an admin" do
      let(:user_role) { User::ADMIN }
      let(:user_lockbox_partner) { nil }

      it "returns 200" do
        expect(response.status).to eq(200)
      end
    end

    context "when the user is not an admin" do
      let(:user_role) { User::PARTNER }
      let(:user_lockbox_partner) { authorized_lockbox_partner }

      it "redirects" do
        expect(response.status).to eq(302)
      end
    end
  end

  describe "#show" do
    before do
      sign_in(user)
      get :show, params: { lockbox_partner_id: authorized_lockbox_partner.id, id: support_request.id }
    end

    context "when the user is an admin" do
      let(:user_role) { User::ADMIN }
      let(:user_lockbox_partner) { nil }

      it "returns 200" do
        expect(response.status).to eq(200)
      end
    end

    context "when the user is not an admin but is a lockbox owner" do
      let(:user_role) { User::PARTNER }
      let(:user_lockbox_partner) { authorized_lockbox_partner }

      it "returns 200" do
        expect(response.status).to eq(200)
      end
    end

    context "when the user is not an admin and does not belong to the lockbox" do
      let(:user_role) { User::PARTNER }
      let(:user_lockbox_partner) { unauthorized_lockbox_partner }

      it "redirects" do
        expect(response.status).to eq(302)
      end
    end
  end

  describe "#update_status" do
    let(:support_request) { create(:support_request, :pending) }
    let(:user) { create(:user, role: User::PARTNER, lockbox_partner: support_request.lockbox_partner) }

    it 'updates the status of the lockbox action associated with the support request' do
      sign_in(user)
      post :update_status, params: {
        lockbox_partner_id: support_request.lockbox_partner_id,
        support_request_id: support_request.id,
        status: 'completed'
      }
      expect(support_request.lockbox_action.reload.status).to eq 'completed'
    end

    it 'updates in less than 1/40th of a second' do
      sign_in(user)
      expect(NoteMailer).not_to receive(:deliver_note_creation_alerts)
      # This is kinda flaky -- might be better to make the call 10 times and take an average.
      expect {
        post :update_status, params: {
          lockbox_partner_id: support_request.lockbox_partner_id,
          support_request_id: support_request.id,
          status: 'completed'
        }
      }.to perform_under(0.025).sec
    end
  end

  describe "#edit" do
    before do
      sign_in(user)
      get :new, params: {
        lockbox_partner_id: authorized_lockbox_partner.id, id: support_request.id
      }
    end

    context "when the user is an admin" do
      let(:user_role) { User::ADMIN }
      let(:user_lockbox_partner) { nil }

      it "returns 200" do
        expect(response.status).to eq(200)
      end
    end

    context "when the user is not an admin" do
      let(:user_role) { User::PARTNER }
      let(:user_lockbox_partner) { authorized_lockbox_partner }

      it "redirects" do
        expect(response.status).to eq(302)
      end
    end
  end

  describe '#update' do
    let(:new_name) { SecureRandom.hex(8) }

    before do
      sign_in(user)
      patch :update, params: {
        lockbox_partner_id: authorized_lockbox_partner.id,
        id: support_request.id,
        support_request: {
          name_or_alias: new_name
        }
      }
    end

    context "when the user is not an admin" do
      let(:user_role) { User::PARTNER }
      let(:user_lockbox_partner) { authorized_lockbox_partner }

      it "redirects to root path" do
        expect(response).to redirect_to(root_path)
      end

      it "does not update the support request" do
        expect(support_request.reload.name_or_alias).not_to eq(new_name)
      end
    end

    context "when the user is an admin" do
      let(:user_role) { User::ADMIN }
      let(:user_lockbox_partner) { nil }

      it "redirects to #show" do
        expect(response).to redirect_to(
          lockbox_partner_support_request_path(support_request)
        )
      end

      it "updates the support request" do
        expect(support_request.reload.name_or_alias).to eq(new_name)
      end
    end
  end
end
