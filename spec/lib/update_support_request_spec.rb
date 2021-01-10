require 'rails_helper'
require './lib/update_support_request'

describe UpdateSupportRequest do

  let(:support_request) { FactoryBot.create(:support_request, :pending) }
  let(:lockbox_transaction) { FactoryBot.create(:lockbox_transaction) }

  before do
    support_request.lockbox_action.lockbox_transactions = [lockbox_transaction]
  end

  it 'updates the support request' do
    expect(support_request).to be_persisted
    result = UpdateSupportRequest.call(support_request: support_request, params: {client_ref_id: '5678'})
    expect(result).to be_success
    expect(result.value).to be_an_instance_of(SupportRequest)
    expect(result.value.client_ref_id).to eq('5678')
  end

  it 'adds a transaction to the support request' do
    expect(support_request).to be_persisted
    result = UpdateSupportRequest.call(support_request: support_request, params: {client_ref_id: '5678',
      lockbox_action_attributes: {
        eff_date: "2019-12-10",
        id: lockbox_transaction.lockbox_action.id,
        lockbox_transactions_attributes: {
        "0": {
          category: "hotel_reimbursement",
          distance: "",
          amount: "10.00",
          _destroy: "false",
          id: lockbox_transaction.id
        },
        "1": {
          category: "food",
          distance: "",
          amount: "12.00",
          balance_effect: LockboxTransaction::DEBIT,
        }
    }}})
    expect(result).to be_success
    expect(result.value).to be_an_instance_of(SupportRequest)
    expect(result.value.client_ref_id).to eq('5678')
  end

  it 'creates a note if certain support request fields were changed' do
    new_values = {
      client_ref_id: 'new client ref',
      name_or_alias: 'new name',
      urgency_flag: 'new urgency',
    }

    new_values.each do |field, value|
      expect{UpdateSupportRequest.call(support_request: support_request, params: {field => value})}
        .to change{Note.count}
        .by(1)
    end

  end

  it 'creates a note flagged with may_contain_pii if the name_or_alias was changed' do
    expect{
      UpdateSupportRequest.call(
        support_request: support_request, params: { name_or_alias: 'new name' }
      )
    }
      .to change{Note.count}
      .by(1)

    expect(Note.last.may_contain_pii).to be true
  end

  it 'does not flag the note with may_contain_pii if any other field was changed' do
    expect{
      UpdateSupportRequest.call(
        support_request: support_request, params: { urgency_flag: 'new flag' }
      )
    }
      .to change{Note.count}
      .by(1)

    expect(Note.last.may_contain_pii).to be false
  end

  it 'creates a note if the total amount was changed' do
    update_params = {
      lockbox_action_attributes: {
        id: support_request.lockbox_action.id,
        lockbox_transactions_attributes: {
          "0" => {
            amount: (lockbox_transaction.amount_cents/100.0 + 1000).to_s,
            _destroy: "false",
            id: lockbox_transaction.id
          }
        }
      }
    }

    expect{UpdateSupportRequest.call(support_request: support_request, params: update_params, current_user: support_request.user)}
      .to change{Note.count}
      .by(1)
    expect(Note.last.text).to include("The Total Amount for this Support Request was changed")
    expect(Note.last.text).to include("Changes made by #{support_request.user.name}.")
  end

  it 'creates a note if the pickup date has changed' do
    update_params = {
      lockbox_action_attributes: {
        eff_date: (support_request.lockbox_action.eff_date + 1.day).strftime("%Y-%m-%d"),
        id: support_request.lockbox_action.id,
      }
    }

    expect{UpdateSupportRequest.call(support_request: support_request, params: update_params, current_user: support_request.user)}
      .to change{Note.count}
      .by(1)
    expect(Note.last.text).to include("The Pickup Date for this Support Request was changed")
    expect(Note.last.text).to include("Changes made by #{support_request.user.name}.")
  end

  it 'creates a note if the status has changed' do
    update_params = {
      lockbox_action_attributes: {
        status: 'completed',
        id: support_request.lockbox_action.id,
      }
    }

    expect{UpdateSupportRequest.call(support_request: support_request, params: update_params, current_user: support_request.user)}
      .to change{Note.count}
      .by(1)
    expect(Note.last.text).to include("The Status for this Support Request was changed")
    expect(Note.last.text).to include("Changes made by #{support_request.user.name}.")
  end

  it 'creates a note with notable_action of "update"' do
    update_params = {
      lockbox_action_attributes: {
        status: 'completed',
        id: support_request.lockbox_action.id,
      }
    }

    expect{UpdateSupportRequest.call(support_request: support_request, params: update_params, current_user: support_request.user)}
      .to change{Note.count}
      .by(1)
    expect(Note.last.notable_action).to eq("update")
  end

  it 'creates a single note if multiple fields changed' do

    expect{UpdateSupportRequest.call(support_request: support_request, params: {client_ref_id: 'new client ref', name_or_alias: 'new name', urgency_flag: 'new urgency'}, current_user: support_request.user)}
      .to change{Note.count}
      .by(1)

    note = Note.last
    expect(note.text).to include("The Client Reference ID for this Support Request was changed")
    expect(note.text).to include("The Client Alias for this Support Request was changed")
    expect(note.text).to include("The Urgency Flag for this Support Request was changed from blank to new urgency.")
    expect(note.text).to include("Changes made by #{support_request.user.name}.")
  end

  it "does not succeed if the support request can't be updated" do
    result = nil
    expect{result = UpdateSupportRequest.call(support_request: support_request, params: {name_or_alias: ''})}
      .to change{Note.count}
      .by(0)

    expect(result).not_to be_success
  end

  it "does not succeed if the amount can't be updated" do
    update_params = {
      lockbox_action_attributes: {
        id: support_request.lockbox_action.id,
        lockbox_transactions_attributes: {
          "0" => {
            amount: "-100.0",
            category: "",
            _destroy: "false",
            id: lockbox_transaction.id
          }
        }
      }
    }

    result = nil
    expect{result = UpdateSupportRequest.call(support_request: support_request, params: update_params)}
      .to change{Note.count}
      .by(0)

    expect(result).not_to be_success
  end

  it "does not succeed if the pickup date can't be updated" do
    update_params = {
      lockbox_action_attributes: {
        eff_date: '',
        id: support_request.lockbox_action.id,
      }
    }

    result = nil
    expect{result = UpdateSupportRequest.call(support_request: support_request, params: update_params)}
      .to change{Note.count}
      .by(0)

    expect(result).not_to be_success
  end
end
