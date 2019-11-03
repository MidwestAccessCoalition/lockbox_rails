require 'rails_helper'
require './lib/create_support_request'
require './lib/add_cash_to_lockbox'

describe CreateSupportRequest do
  let(:mac_user) { FactoryBot.create(:user) }
  let(:lockbox_partner) do
    FactoryBot.create(:lockbox_partner, :active)
  end

  let(:params) do
    {
      client_ref_id:      "1234",
      name_or_alias:      "some name",
      urgency_flag:       "urgent",
      lockbox_partner_id: lockbox_partner.id,
      lockbox_action: {
        eff_date:         Date.current,
        lockbox_transactions: [
          {
            amount:       42.42,
            category:     "gas"
          }
        ]
      },
      user_id:            mac_user.id,
    }
  end

  it 'works' do
    result = CreateSupportRequest.call(params: params)
    expect(result).to be_success
    expect(result.value).to be_an_instance_of(SupportRequest)
  end

  it "creates a note" do
    expect{CreateSupportRequest.call(params: params)}
      .to change{Note.count}
      .by(1)
  end

  context "partner notification email" do
    let(:delivery) do
      instance_double(
        ActionMailer::Parameterized::MessageDelivery,
        deliver_now: nil
      )
    end

    let(:mailer) { double(creation_alert: delivery) }

    before do
      allow(SupportRequestMailer).to receive(:with).and_return(mailer)

      CreateSupportRequest.call(params: params)
    end

    it "sends the email" do
      expect(delivery).to have_received(:deliver_now)
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
        lockbox_action: {
          eff_date:         Date.current,
          lockbox_transactions: [
            {
              amount:       1,
              category:     "gas"
            }
          ]
        },
        user_id:            mac_user.id,
      }
    end

    before do
      AddCashToLockbox.call!(lockbox_partner: low_balance_lockbox_partner, eff_date: 1.day.ago, amount: LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE).complete!
    end

    it 'goes to the finance team when balance is below $300' do
      ENV['LOW_BALANCE_ALERT_EMAIL'] = 'lowbalance@alert.com'

      result = nil

      expect { result = CreateSupportRequest.call(params: low_balance_params) }
        .to change{ActionMailer::Base.deliveries.length}.by(2)
      expected_dollar_value = (LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE - Money.new(100)).to_s

      mail = ActionMailer::Base.deliveries.last
      expect(mail).to be_present
      expect(mail.to).to include ENV['LOW_BALANCE_ALERT_EMAIL']

      expect(mail.parts.detect{|p| p.mime_type == "text/plain"}.body.raw_source).to include expected_dollar_value
      expect(mail.parts.detect{|p| p.mime_type == "text/html"}.body.raw_source).to include expected_dollar_value
    end

    # The deliveries count will still change by 1 because the creation alert was
    # still sent

    it "doesn't blow up when email is missing" do
      ENV['LOW_BALANCE_ALERT_EMAIL'] = nil

      expect { CreateSupportRequest.call(params: low_balance_params) }
        .to change{ActionMailer::Base.deliveries.length}.by(1)
    end

    it 'is not sent when the balance remains above $300' do
      ENV['LOW_BALANCE_ALERT_EMAIL'] = 'lowbalance@alert.com'

      AddCashToLockbox.call!(lockbox_partner: lockbox_partner, eff_date: 1.day.ago, amount: LockboxPartner::MINIMUM_ACCEPTABLE_BALANCE + Money.new(15000)).complete!

      params[:lockbox_action][:lockbox_transactions][0][:amount] = 100
      expect { CreateSupportRequest.call(params: params) }
        .to change{ActionMailer::Base.deliveries.length}.by(1)
    end
  end
end
