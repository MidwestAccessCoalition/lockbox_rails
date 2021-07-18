require 'rails_helper'

describe NoteMailer, type: :mailer do
  let!(:admin_user) { FactoryBot.create(:user) }
  let!(:admin_user2) { FactoryBot.create(:user) }
  let!(:locked_admin_user) { create(:user, locked_at: Time.now) }
  let(:lockbox_partner) { FactoryBot.create(:lockbox_partner, :active) }
  let(:support_request) do
    FactoryBot.create(:support_request, :pending, lockbox_partner: lockbox_partner)
  end
  let(:urgent_support_request) do
    FactoryBot.create(:support_request, :pending, lockbox_partner: lockbox_partner, urgency_flag: "Super Urgent")
  end

  let(:admin_note) do
    FactoryBot.create(:note, user: admin_user, notable: support_request)
  end
  let(:system_note) do
    FactoryBot.create(:note, user: nil, notable: support_request)
  end
  let(:partner_note) do
    FactoryBot.create(:note, user: lockbox_partner.users.first, notable: support_request)
  end
  let(:support_request_creation_note) do
    FactoryBot.create(:note, user: lockbox_partner.users.first, notable: support_request, notable_action: "create")
  end
  let(:urgent_support_request_creation_note) do
    FactoryBot.create(:note, user: lockbox_partner.users.first, notable: urgent_support_request, notable_action: "create")
  end

  describe "#note_creation_alert" do
    describe "content" do
      before do
        admin_note
        NoteMailerWorker.drain
      end

      it "has the expected subject line" do
        email = ActionMailer::Base.deliveries.first
        expected_subject = "New note from #{admin_note.author} on Support Request ##{admin_note.notable_id}"
        expect(email.subject).to eq(expected_subject)
      end

      it "includes a link to the support_request" do
        email = ActionMailer::Base.deliveries.first
        path = "/lockbox_partners/#{lockbox_partner.id}/support_requests/#{admin_note.notable_id}"
        expect(email.body.encoded).to include(path)
      end
    end

    context "for a system note" do
      before do
        system_note
        NoteMailerWorker.drain
      end

      it "has the expected subject line" do
        email = ActionMailer::Base.deliveries.first
        expected_subject = "New System note on Support Request ##{system_note.notable_id}"
        expect(email.subject).to eq(expected_subject)
      end
    end

    context "when an admin user creates the note" do
      before do
        admin_note
        NoteMailerWorker.drain
      end

      it "emails the lockbox partner's users" do
        admin_note.notable.lockbox_partner.users.pluck(:email).compact.each do |address|
          expect(recipients).to include(address)
        end
      end

      it "emails the other admins" do
        expect(User.admin.count).to be > 1 # need to make sure we're emailing OTHER admins
        (User.admin.active.pluck(:email) - [admin_note.user.email]).compact.each do |address|
          expect(recipients).to include(address)
        end
        expect(recipients).to_not include(User.where.not(locked_at: nil).pluck(:email))
      end
    end

    context "when a partner user creates the note" do
      before do
        partner_note
        NoteMailerWorker.drain
      end

      it "emails the lockbox partner's users" do
        partner_note.notable.lockbox_partner.users.pluck(:email).compact.each do |address|
          expect(recipients).to include(address)
        end
      end

      it "emails all the active admins" do
        expect(User.admin.count).to be > 1 # need to make sure we're emailing OTHER admins
        User.admin.each do |admin|
          if admin.locked_at?
            expect(recipients).to_not include(admin.email)
          else
            expect(recipients).to include(admin.email)
          end
        end
      end
    end

    context "for a support request creation" do
      context "when there is no urgency flag" do
        it "has the expected subject line" do
          support_request_creation_note
          NoteMailerWorker.drain
          email = ActionMailer::Base.deliveries.first
          expect(email.subject).to eq("MAC Cash Box Withdrawal Request")
        end
      end

      context "when there is an urgency flag" do
        before do
          urgent_support_request_creation_note
          NoteMailerWorker.drain
        end
        it "has the expected subject line" do
          urgent_support_request_creation_note
          email = ActionMailer::Base.deliveries.first
          expect(email.subject).to eq("Super Urgent - MAC Cash Box Withdrawal Request")
        end
      end

      context "body" do
        before do
          support_request_creation_note
          NoteMailerWorker.drain
          @email = ActionMailer::Base.deliveries.first
        end

        it "includes the pickup date" do
          expect(@email.body.encoded).to include(
            support_request.pickup_date.strftime("%A, %B %d, %Y")
          )
        end

        it "includes the amount" do
          expect(@email.body.encoded).to include(support_request.amount.format)
        end

        it "includes the coordinator's name" do
          expected_name = ERB::Util.html_escape(support_request.user.name)
          expect(@email.body.encoded).to include(expected_name)
        end

        it "includes a link to the support_request" do
          path = "/lockbox_partners/#{lockbox_partner.id}/support_requests/#{support_request.id}"
          expect(@email.body.encoded).to include(path)
        end
      end

    end
  end

  def recipients
    ActionMailer::Base.deliveries.collect(&:to).flatten
  end
end
