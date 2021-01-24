require 'rails_helper'

describe SupportRequestRedactionWorker do
  let!(:support_request) { FactoryBot.create(:support_request) }

  before { subject.perform(support_request.id) }

  it "redacts the support request" do
    expect(support_request.reload.name_or_alias).to eq(SupportRequest::REDACTED)
  end
end