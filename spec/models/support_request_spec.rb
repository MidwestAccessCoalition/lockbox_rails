require 'rails_helper'
require './lib/create_support_request'

describe SupportRequest, type: :model do
  it { is_expected.to belong_to(:lockbox_partner) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_one(:lockbox_action) }
  it { is_expected.to have_many(:notes) }

  it { is_expected.to validate_presence_of(:name_or_alias) }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:lockbox_partner) }

  describe 'status scopes' do
    let!(:pending_request) { FactoryBot.create(:support_request, :pending) }
    let!(:completed_request) { FactoryBot.create(:support_request, :completed) }
    let!(:canceled_request) { FactoryBot.create(:support_request, :canceled) }

    it 'returns only pending support requests' do
      results = SupportRequest.pending

      expect(results).to     include(pending_request)
      expect(results).not_to include(completed_request)
      expect(results).not_to include(canceled_request)
    end

    it 'returns only completed support requests' do
      results = SupportRequest.completed

      expect(results).not_to include(pending_request)
      expect(results).to     include(completed_request)
      expect(results).not_to include(canceled_request)
    end

    it 'returns only canceled support requests' do
      results = SupportRequest.canceled

      expect(results).not_to include(pending_request)
      expect(results).not_to include(completed_request)
      expect(results).to     include(canceled_request)
    end
  end

  describe 'partner status scopes' do
    let!(:pending_wrong_partner) { FactoryBot.create(:support_request, :pending) }
    let!(:completed_wrong_partner) { FactoryBot.create(:support_request, :completed) }
    let!(:canceled_wrong_partner) { FactoryBot.create(:support_request, :canceled) }
    let!(:pending_right_partner) { FactoryBot.create(:support_request, :pending) }
    let!(:completed_right_partner) { FactoryBot.create(:support_request, :completed) }
    let!(:canceled_right_partner) { FactoryBot.create(:support_request, :canceled) }

    let(:right_partner) { FactoryBot.create(:lockbox_partner) }
    let(:wrong_partner) { FactoryBot.create(:lockbox_partner) }

    before do
      pending_wrong_partner.update(lockbox_partner: wrong_partner)
      completed_wrong_partner.update(lockbox_partner: wrong_partner)
      canceled_wrong_partner.update(lockbox_partner: wrong_partner)

      pending_right_partner.update(lockbox_partner: right_partner)
      completed_right_partner.update(lockbox_partner: right_partner)
      canceled_right_partner.update(lockbox_partner: right_partner)
    end

    it 'returns only pending support requests' do
      results = SupportRequest.pending_for_partner(lockbox_partner_id: right_partner.id)

      expect(results).to     include(pending_right_partner)
      expect(results).not_to include(completed_right_partner)
      expect(results).not_to include(canceled_right_partner)

      expect(results).not_to include(pending_wrong_partner)
      expect(results).not_to include(completed_wrong_partner)
      expect(results).not_to include(canceled_wrong_partner)
    end

    it 'returns only completed support requests' do
      results = SupportRequest.completed_for_partner(lockbox_partner_id: right_partner.id)

      expect(results).not_to include(pending_right_partner)
      expect(results).to     include(completed_right_partner)
      expect(results).not_to include(canceled_right_partner)

      expect(results).not_to include(pending_wrong_partner)
      expect(results).not_to include(completed_wrong_partner)
      expect(results).not_to include(canceled_wrong_partner)
    end

    it 'returns only canceled support requests' do
      results = SupportRequest.canceled_for_partner(lockbox_partner_id: right_partner.id)

      expect(results).not_to include(pending_right_partner)
      expect(results).not_to include(completed_right_partner)
      expect(results).to     include(canceled_right_partner)

      expect(results).not_to include(pending_wrong_partner)
      expect(results).not_to include(completed_wrong_partner)
      expect(results).not_to include(canceled_wrong_partner)
    end
  end

  describe '.needs_redaction' do
    let(:recent_completed_lockbox_action) do
      create(:lockbox_action, :completed).tap do |la|
        # closed_at must be set separately, or a callback will overwrite it
        la.update!(closed_at: (SupportRequest::REDACT_AFTER_DAYS - 1).days.ago)
      end
    end

    let!(:recent_completed_support_request) do
      create(:support_request, lockbox_action: recent_completed_lockbox_action)
    end

    let(:recent_canceled_lockbox_action) do
      create(:lockbox_action, :canceled).tap do |la|
        la.update!(closed_at: (SupportRequest::REDACT_AFTER_DAYS - 1).days.ago)
      end
    end

    let!(:recent_canceled_support_request) do
      create(:support_request, lockbox_action: recent_canceled_lockbox_action)
    end

    let(:recent_pending_lockbox_action) do
      create(:lockbox_action, status: LockboxAction::PENDING).tap do |la|
        la.update!(closed_at: (SupportRequest::REDACT_AFTER_DAYS - 1).days.ago)
      end
    end

    let!(:recent_pending_support_request) do
      create(:support_request, lockbox_action: recent_pending_lockbox_action)
    end

    let(:old_completed_lockbox_action) do
      create(:lockbox_action, :completed).tap do |la| 
        la.update!(closed_at: (SupportRequest::REDACT_AFTER_DAYS).days.ago)
      end
    end

    let!(:old_completed_support_request) do
      create(:support_request, lockbox_action: old_completed_lockbox_action)
    end

    let(:old_canceled_lockbox_action) do
      create(:lockbox_action, :canceled).tap do |la|
        la.update!(closed_at: (SupportRequest::REDACT_AFTER_DAYS).days.ago)
      end
    end

    let!(:old_canceled_support_request) do
      create(:support_request, lockbox_action: old_canceled_lockbox_action)
    end

    let(:old_pending_lockbox_action) do
      create(:lockbox_action,  status: LockboxAction::PENDING).tap do |la|
        la.update!(closed_at: (SupportRequest::REDACT_AFTER_DAYS).days.ago)
      end
    end

    let!(:old_pending_support_request) do
      create(:support_request, lockbox_action: old_pending_lockbox_action)
    end

    let(:old_completed_lockbox_action_2) do
      create(:lockbox_action, :completed).tap do |la|
        la.update!(closed_at: (SupportRequest::REDACT_AFTER_DAYS).days.ago)
      end
    end

    let!(:already_redacted_support_request) do
      create(
        :support_request,
        lockbox_action: old_completed_lockbox_action_2,
        redacted: true
      )
    end

    subject { SupportRequest.needs_redaction.pluck(:id) }

    it 'does not include recent completed support requests' do
      expect(subject).not_to include(recent_completed_support_request.id)
    end

    it 'does not include recent canceled support requests' do
      expect(subject).not_to include(recent_canceled_support_request.id)
    end

    it 'does not include recent support requests that are still pending' do
      expect(subject).not_to include(recent_pending_support_request.id)
    end

    it 'includes old completed support requests' do
      expect(subject).to include(old_completed_support_request.id)
    end

    it 'includes old canceled support requests' do
      expect(subject).to include(old_canceled_support_request.id)
    end

    it 'does not include old support requests that are still pending' do
      expect(subject).not_to include(old_pending_support_request.id)
    end

    it 'does not include old completed support requests that are redacted already' do
      expect(subject).not_to include(already_redacted_support_request.id)
    end
  end

  describe 'record_creation' do
    let(:support_req)   { FactoryBot.create(:support_request) }
    let(:name)          { "FancyPants McGee" }
    let(:user)          { instance_double(User, name: name) }
    let(:expected_text) { "Support request generated by #{name}" }

    before { allow(support_req).to receive(:user).and_return(user) }
    it 'generates a note with the expected text' do
      expect { support_req.record_creation }
        .to change { support_req.notes.count }.by(1)
      note = support_req.notes.last
      expect(note.text).to eq(expected_text)
    end
  end

  describe '#redact!' do
    let(:support_request) { FactoryBot.create(:support_request) }
    let(:user) { FactoryBot.create(:user) }

    let!(:note1) do
      FactoryBot.create(
        :note, notable: support_request, user: nil, may_contain_pii: true
      )
    end

    let!(:note2) do
      FactoryBot.create(
        :note,
        notable: support_request,
        user: user,
        may_contain_pii: false
      )     
    end

    let!(:note3) do
      FactoryBot.create(
        :note, notable: support_request, user: nil, may_contain_pii: false
      )
    end

    before { support_request.redact! }

    it "redacts the name_or_alias" do
      expect(support_request.name_or_alias).to eq(SupportRequest::REDACTED)
    end

    it "marks the support request as redacted" do
      expect(support_request.redacted).to be true
    end

    it "redacts system-generated notes that may contain PII" do
      expect(note1.reload.text).to eq(SupportRequest::REDACTED)
    end

    it "redacts user-generated notes" do
      expect(note2.reload.text).to eq(SupportRequest::REDACTED)
    end

    it "does not redact system-generated notes without PII" do
      expect(note3.reload.text).not_to eq(SupportRequest::REDACTED)
    end
  end
end
