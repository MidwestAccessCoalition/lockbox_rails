require 'rails_helper'

describe LockboxPartnerMailer, type: :mailer do
  let(:lockbox_partner) { FactoryBot.create(:lockbox_partner, :active) }

  describe "#low_balance_alert" do
    let(:low_balance_alert_email) { "lowbalancealert@example.com" }
    let(:lockbox_email) { "lockboxemail@example.com" }

    let(:email) do
      described_class
        .with(lockbox_partner: lockbox_partner)
        .low_balance_alert
        .deliver_now
    end

    let!(:admin) { FactoryBot.create(:user) }

    let!(:locked_admin) { FactoryBot.create(:user, locked_at: Time.now) }

    before do
      allow(ENV)
        .to receive(:[])
        .and_call_original
      allow(ENV)
        .to receive(:[])
        .with("LOW_BALANCE_ALERT_EMAIL")
        .and_return(low_balance_alert_email)
      allow(ENV)
        .to receive(:[])
        .with("LOCKBOX_EMAIL")
        .and_return(lockbox_email)
    end

    it "sends the email to the address specified in the env vars" do
      expect(email.to).to eq([low_balance_alert_email, lockbox_email])
    end

    it "ccs the active admin emails" do
      expect(User.admin.count).to eq(2)
      expect(admin.email).to eq(User.get_active_admin_emails)
      expect(email.cc).to eq([admin.email])
    end

    it "has the expected subject line" do
      expect(email.subject).to eq(
        "[LOW LOCKBOX BALANCE] #{lockbox_partner.name} needs cash"
      )
    end

    it "alerts the recipient to the low balance" do
      alert_text = "The lockbox balance at <b>#{lockbox_partner.name}</b> is at " \
                   "<b>$#{lockbox_partner.balance.to_s}</b>"
      # `CGI.unescapeHTML` turns HTML entities back into chars (e.g. `&#39;` back into `'`)
      expect(CGI.unescapeHTML(email.body.encoded)).to include(alert_text)
    end
  end

  describe "#reconciliation_completed_alert" do
    let(:lockbox_email) { "lockbox@example.com" }
    let(:lockbox_url) { "lockbox.example.com" }
    let(:finance_email) { "finance@example.com" }
    let(:amount) { Money.new(35010) }

    let(:email) do
      described_class
        .with(lockbox_partner: lockbox_partner, amount: amount)
        .reconciliation_completed_alert
        .deliver_now
    end

    before do
      allow(ENV)
        .to receive(:[])
        .and_call_original
      allow(ENV)
        .to receive(:[])
        .with("LOCKBOX_EMAIL")
        .and_return(lockbox_email)
      allow(ENV)
        .to receive(:[])
        .with("FINANCE_EMAIL")
        .and_return(finance_email)
      allow(ENV)
        .to receive(:[])
        .with("HOST")
        .and_return(lockbox_url)
    end

    it "sends the email to the addresses specified in an env vars" do
      expect(email.to).to match_array([lockbox_email, finance_email])
    end

    it "has the expected subject line" do
      expect(email.subject).to eq(
        "#{lockbox_partner.name} lockbox reconciled: $350.10"
      )
    end

    it "alerts the recipient to the reconciliation" do
      alert_text = "#{lockbox_partner.name} lockbox has been reconciled and no further action needs to be taken."
      expect(CGI.unescapeHTML(email.body.encoded)).to include(alert_text)
    end

    it "includes helpful links" do
      expect(CGI.unescapeHTML(email.body.encoded)).to include(lockbox_url)
      expect(CGI.unescapeHTML(email.body.encoded)).to include(lockbox_email)
    end
  end

  describe "#reconciliation_overdue_alert" do
    let(:lockbox_email) { "lockbox@example.com" }
    let(:lockbox_url) { "lockbox.example.com" }

    let(:email) do
      described_class
        .with(lockbox_partner: lockbox_partner)
        .reconciliation_overdue_alert
        .deliver_now
    end

    let!(:last_reconciliation) {
      Timecop.freeze(40.days.ago) {
        FactoryBot.create(:lockbox_action, :reconciliation, lockbox_partner: lockbox_partner)
      }
    }

    before do
      allow(ENV)
        .to receive(:[])
        .and_call_original
      allow(ENV)
        .to receive(:[])
        .with("LOCKBOX_EMAIL")
        .and_return(lockbox_email)
      allow(ENV)
        .to receive(:[])
        .with("HOST")
        .and_return(lockbox_url)
    end

    it "sends the email to the addresses specified in an env vars" do
      expect(email.to).to eq([lockbox_email])
    end

    it "has the expected subject line" do
      expect(email.subject).to eq(
        "#{lockbox_partner.name} reconciliation overdue"
      )
    end

    it "alerts the recipient to the overdue reconciliation, specifying time since reconciliation" do
      alert_text = "#{lockbox_partner.name} has not reconciled their lockbox in 40 days."
      expect(CGI.unescapeHTML(email.body.encoded)).to include(alert_text)
    end

    it "includes helpful links" do
      expect(CGI.unescapeHTML(email.body.encoded)).to include(lockbox_url)
      expect(CGI.unescapeHTML(email.body.encoded)).to include(lockbox_email)
    end
  end
end
