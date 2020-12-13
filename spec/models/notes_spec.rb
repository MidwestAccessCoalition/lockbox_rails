require 'rails_helper'

describe Note, type: :model do
  it { is_expected.to belong_to(:notable) }
  it { is_expected.to belong_to(:user).optional }

  context "callbacks" do
    let(:user) { FactoryBot.create(:user) }
    let(:notable) { FactoryBot.create(:support_request) }
    let(:note) { FactoryBot.build(:note, user: user, notable: notable) }

    describe "email alert" do
      let(:delivery) do
        instance_double(
          ActionMailer::Parameterized::MessageDelivery,
          deliver_now: nil
        )
      end

      let(:mailer) { double(note_creation_alert: delivery) }

      it "kicks off email alerts" do
        expect(NoteMailerWorker).to receive(:perform_async)
        note.save
      end
    end
  end

  describe "#redact!" do
    let(:note) { FactoryBot.create(:note, text: "TEXT") }

    before { note.redact! }

    it "redacts PII" do
      expect(note.text).to eq(SupportRequest::REDACTED)
    end
  end
end
