class SupportRequestRedactionWorker
  include Sidekiq::Worker

  def perform(support_request_id)
    support_request = SupportRequest.find_by(id: support_request_id)
    return unless support_request
    support_request.redact!
  end
end
