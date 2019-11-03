require 'rails_helper'

describe Note, type: :model do
  it { is_expected.to belong_to(:notable) }
  it { is_expected.to belong_to(:user).optional }

  context "callbacks" do
    let(:note) { FactoryBot.build(:note, user: user, notable: notable) }

    describe "email alert" do
      let(:delivery) do
        instance_double(
          ActionMailer::Parameterized::MessageDelivery,
          deliver_now: nil
        )
      end

      let(:mailer) { double(single_note: delivery) }

      before do
        allow(NoteMailer).to receive(:with).and_return(mailer)
        note.save
      end

      context "when the note is not system-generated and belongs to a SupportRequest" do
        let(:user) { FactoryBot.create(:user) }
        let(:notable) { FactoryBot.create(:support_request) }

        it "sends an email alert" do
          expect(delivery).to have_received(:deliver_now)
        end
      end

      context "when the note is system-generated and belongs to a SupportRequest" do
        let(:user) { nil }
        let(:notable) { FactoryBot.create(:support_request) }

        it "does not send an email alert" do
          expect(delivery).not_to have_received(:deliver_now)
        end
      end

      context "when the note is not system-generated and does not belong to a SupportRequest" do
        let(:user) { FactoryBot.create(:user) }
        let(:notable) { FactoryBot.create(:user) }

        it "does not send an email alert" do
          expect(delivery).not_to have_received(:deliver_now)
        end
      end

      context "when the note is system-generated and does not belong to a SupportRequest" do
        let(:user) { nil }
        let(:notable) { FactoryBot.create(:user) }

        it "does not send an email alert" do
          expect(delivery).not_to have_received(:deliver_now)
        end
      end
    end
  end
end
