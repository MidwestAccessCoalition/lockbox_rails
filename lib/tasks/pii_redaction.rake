namespace :pii_redaction do
  # These two tasks are intended to fix records that were created before PII
  # redaction was implemented. If the code that supports redaction has always
  # been active since the database was created, there's no need for them,
  # although they would be safe to run.

  desc "Backfill lockbox_actions.closed_at where it was not recorded"
  task backfill_closed_at: :environment do
    ActiveRecord::Base.transaction do
      LockboxAction.where(
        status: LockboxAction::CLOSED_STATUSES,
        closed_at: nil
      ).each { |la| la.update!(closed_at: la.updated_at) }
    end
  end

  desc "Delete any version records that recorded changes to name_or_alias"
  task redact_versions: :environment do
    PaperTrail::Version
      .where("object_changes LIKE ?", "%name_or_alias%")
      .delete_all
  end
end