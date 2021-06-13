require 'rails_helper'
require './lib/create_support_request'
require './lib/add_cash_to_lockbox'

describe CreateSupportRequest do
  def drain_queues
    NotesWorker.drain
    NoteMailerWorker.drain
    LowBalanceAlertWorker.drain
  end

  let!(:mac_user) { FactoryBot.create(:user) }

  let(:lockbox_partner) do
    FactoryBot.create(:lockbox_partner, :active)
  end

  let(:lockbox_transactions) do
    {
      "0" => {
        amount:       42.42,
        category:     "gas"
      }
    }
  end

  let(:params) do
    {
      client_ref_id:      "1234",
      name_or_alias:      "some name",
      urgency_flag:       "urgent",
      lockbox_partner_id: lockbox_partner.id,
      lockbox_action_attributes: {
        eff_date:         Date.current,
        lockbox_transactions_attributes: lockbox_transactions
      },
      user_id:            mac_user.id,
    }
  end

  subject { CreateSupportRequest.call(params: params) }

  it 'creates one note and triggers two emails' do
    get_request_emails = lambda do
      ActionMailer::Base.deliveries.reject do |delivery|
        delivery.subject['MAC Cash Box Withdrawal Request'].nil?
      end
    end
    notes_count = Note.count
    emails_count = get_request_emails.call.count

    result = nil

    expect {
      result = subject
      drain_queues
    }.to change {
      [Note.count, get_request_emails.call.count]
    }.from([notes_count, emails_count]).to([notes_count+1, emails_count+2])

    expect(result).to be_success
    expect(result.value).to be_an_instance_of(SupportRequest)
  end

  context "if creation of the lockbox action fails" do
    before { allow(LockboxAction).to receive(:create).and_return(LockboxAction.new) }

    it "does not create a support request" do
      result = nil
      expect{ result = subject }.not_to change(SupportRequest, :count)
      expect(result).not_to be_success
    end
  end

  context "if no lockbox transactions are provided" do
    let(:lockbox_transactions) { nil }

    it "does not create a support request" do
      result = nil
      expect{ result = subject }.not_to change(SupportRequest, :count)
      expect(result).not_to be_success
    end
  end

  context "when one of the lockbox transactions has no category" do
    let(:lockbox_transactions) do
      {
        "0" => {
          amount:   42.42,
          category: "gas"
        },
        "1" => {
          amount:   10.00
        }
      }
    end

    it "does not create a support request" do
      result = nil
      expect{ result = subject }.not_to change(SupportRequest, :count)
      expect(result).not_to be_success
    end
  end

  context "when one of the lockbox transactions has no amount" do
    let(:lockbox_transactions) do
      {
        "0": {
          amount:   42.42,
          category: "gas"
        },
        "1": {
          amount:   "",
          category: "gas"
        }
      }
    end

    it "does not create a support request" do
      result = nil
      expect{ result = subject }.not_to change(SupportRequest, :count)
      expect(result).not_to be_success
    end
  end

  context "when one of the lockbox transactions is completely blank" do
    let(:lockbox_transactions) do
      {
        "0": {
          amount: 42.42,
          category: "gas"
        },
        "1": {
          amount: "",
          category: ""
        }
      }
    end

    it "succeeds and creates a support request" do
      result = nil
      expect{ result = subject }.to change(SupportRequest, :count).by(1)
      expect(result).to be_success
    end
  end

  context "partner notification email" do
    it "sends the email" do
      allow(NoteMailer).to receive(:deliver_note_creation_alerts)
      CreateSupportRequest.call(params: params)
      drain_queues
      expect(NoteMailer).to have_received(:deliver_note_creation_alerts)
    end
  end

  describe "low balance alert" do
    let(:low_balance_lockbox_partner) { FactoryBot.create(:lockbox_partner, :active) }
    let(:low_balance_params) do
      {
        client_ref_id:      "1234",
        name_or_alias:      "some name",
        urgency_flag:       "urgent",
        lockbox_partner_id: low_balance_lockbox_partner.id,
        lockbox_action_attributes: {
          eff_date:         Date.current,
          lockbox_transactions_attributes: {
            "0": {
              amount:       1,
              category:     "gas"
            }
          }
        },
        user_id:            mac_user.id,
      }
    end

    before do
      AddCashToLockbox.call!(lockbox_partner: low_balance_lockbox_partner, eff_date: 1.day.ago, amount: lockbox_partner.minimum_acceptable_balance_formatted).complete!
    end

    it 'goes to the finance team when balance is below $300' do
      stub_const('ENV', ENV.to_hash.merge('LOW_BALANCE_ALERT_EMAIL' => 'lowbalance@alert.com'))

      expect {
        CreateSupportRequest.call(params: low_balance_params)
        drain_queues
      }.to change{ActionMailer::Base.deliveries.length}.by(3)

      expected_dollar_value = (lockbox_partner.minimum_acceptable_balance_formatted - Money.new(100)).to_s

      emails = ActionMailer::Base.deliveries.last(3)
      mail = emails.detect {|e| e.subject.include?('[LOW LOCKBOX BALANCE]') }
      expect(mail).to be_present
      expect(mail.to).to include ENV['LOW_BALANCE_ALERT_EMAIL']

      expect(mail.parts.detect{|p| p.mime_type == "text/plain"}.body.raw_source).to include expected_dollar_value
      expect(mail.parts.detect{|p| p.mime_type == "text/html"}.body.raw_source).to include expected_dollar_value
    end

    # Are we sure we don't want it to blow up when this email is missing?
    it "doesn't blow up when email is missing" do
      stub_const('ENV', ENV.to_hash.merge('LOW_BALANCE_ALERT_EMAIL' => nil))

      expect {
        CreateSupportRequest.call(params: low_balance_params)
        drain_queues
      }.to change{ActionMailer::Base.deliveries.length}.by(3)
    end

    it 'is not sent when the balance remains above $300' do
      stub_const('ENV', ENV.to_hash.merge('LOW_BALANCE_ALERT_EMAIL' => 'lowbalance@alert.com'))

      AddCashToLockbox.call!(lockbox_partner: lockbox_partner, eff_date: 1.day.ago, amount: lockbox_partner.minimum_acceptable_balance_formatted + Money.new(15000)).complete!

      params[:lockbox_action_attributes][:lockbox_transactions_attributes]["0"][:amount] = 100
      expect {
        CreateSupportRequest.call(params: params)
        drain_queues
      }.to change{ActionMailer::Base.deliveries.length}.by(2)
    end
  end

  describe "insufficient funds alert" do
    let(:insufficient_funds_lockbox_partner) { FactoryBot.create(:lockbox_partner, :active) }
    let(:insufficient_funds_params) do
      {
        client_ref_id:      "1234",
        name_or_alias:      "some name",
        urgency_flag:       "urgent",
        lockbox_partner_id: insufficient_funds_lockbox_partner.id,
        lockbox_action_attributes: {
          eff_date:         Date.current,
          lockbox_transactions_attributes: {
            "0": {
              amount:       Money.new(1100),
              category:     "gas"
            }
          }
        },
        user_id:            mac_user.id,
      }
    end

    before do
      AddCashToLockbox.call!(
        lockbox_partner: insufficient_funds_lockbox_partner,
        eff_date: 1.day.ago,
        amount: Money.new(1000)
      ).complete!
    end

    it 'goes to the lockbox email address when balance is below $0' do
      stub_const('ENV', ENV.to_hash.merge('LOCKBOX_EMAIL' => 'insufficientfunds@alert.com'))

      result = nil

      expect {
        result = CreateSupportRequest.call(params: insufficient_funds_params)
        drain_queues
      }.to change{ ActionMailer::Base.deliveries.length }.by(3)

      emails = ActionMailer::Base.deliveries.last(3)
      mail = emails.detect {|e| e.subject.include?('[INSUFFICIENT LOCKBOX FUNDS]') }
      expect(mail).to be_present
      expect(mail.to).to include ENV['LOCKBOX_EMAIL']

      expect(mail.parts.detect { |p| p.mime_type == "text/plain" }.body.raw_source)
        .to include insufficient_funds_lockbox_partner.name
      expect(mail.parts.detect{ |p| p.mime_type == "text/html" }.body.raw_source)
        .to include CGI.escapeHTML(insufficient_funds_lockbox_partner.name)
    end

    it "doesn't blow up when email is missing" do
      stub_const('ENV', ENV.to_hash.merge('LOCKBOX_EMAIL' => nil))

      expect {
        CreateSupportRequest.call(params: insufficient_funds_params)
        drain_queues
      }.to change { ActionMailer::Base.deliveries.length }.by(2)
    end
  end
end
