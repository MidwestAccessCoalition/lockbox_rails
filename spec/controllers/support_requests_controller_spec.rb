require 'rails_helper'

describe SupportRequestsController do

  describe "#index" do
    context "when the user is an admin" do
      let(:user) { create(:user) }
      it "returns 200" do
        sign_in(user)
        get :index
        expect(response.status).to eq(200)
      end
    end

    context "when the user is not an admin" do
      let(:user) { create(:user, :partner_user) }
      it "returns 302" do
        sign_in(user)
        get :index
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#export' do
    let(:csv_string) { Time.use_zone(user.time_zone) { SupportRequest.to_csv } }

    before do
      create(:support_request, :pending)
      create(:support_request, :completed)
    end

    context 'when user is admin' do
      let(:user) { create(:user) }
      it 'should return a csv attachment' do
        sign_in(user)
        get :export, format: 'csv'
        expect(response.parsed_body).to eq(csv_string)
      end
    end

    context 'when user is not admin' do
      let(:user) { create(:user, :partner_user) }
      it 'should return a csv attachment' do
        sign_in(user)
        get :export, format: 'csv'
        expect(response.parsed_body).to have_content('You are being')
      end
    end
  end
end

