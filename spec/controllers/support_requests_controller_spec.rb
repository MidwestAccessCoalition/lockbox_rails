require 'rails_helper'

describe SupportRequestsController do

  describe "#index" do
    context "when the user is an admin" do
      it "returns 200" do
        user = create(:user, role: User::ADMIN)
        sign_in(user)
        get :index
        expect(response.status).to eq(200)
      end
    end

    context "when the user is not an admin" do
      it "returns 302" do
        user = create(:user, role: User::PARTNER)
        sign_in(user)
        get :index
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#export' do
    let(:csv_string) { SupportRequest.to_csv }

    before do
      FactoryBot.create(:support_request, :pending)
      FactoryBot.create(:support_request, :completed)
    end

    context 'when user is admin' do
      it 'should return a csv attachment' do
        admin_user = create(:user, role: User::ADMIN)
        sign_in(admin_user)
        get :export, format: 'csv'
        expect(response.parsed_body).to eq(csv_string)
      end
    end

    context 'when user is not admin' do
      it 'should return a csv attachment' do
        user = create(:user, role: User::PARTNER)
        sign_in(user)
        get :export, format: 'csv'
        expect(response.parsed_body).to have_content('You are being')
      end
    end
  end
end

