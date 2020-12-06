require 'verbalize'

class UpdateSupportRequest
  include Verbalize::Action

  # This is what params input looks like
  #
  # {
  #   lockbox_action_attributes: {
  #     eff_date: "2019-09-04",
  #     id: "6",
  #     lockbox_transactions_attributes: {
  #       "0": {
  #         amount: "33.16",
  #         category: "",
  #         _destroy: "false",
  #         id: "7"
  #       },
  #       1: {
  #         ...
  #       },
  #     }
  #   },
  #   name_or_alias: "Foster",
  #   client_ref_id: "qwertyuiopp",
  #   urgency_flag: "one"
  # }
  #
  # We'll pass it directly to SupportRequest to take advantage of AcceptsNestedAttributes.
  input :support_request, :params, optional: [:current_user]

  attr_accessor :support_request, :original_values

  def call
    cache_original_values

    if support_request.update(params)
      notate_changes
    else
      fail!(support_request.errors.full_messages.join(". "))
    end

    support_request
  end

  private

  def cache_original_values
    self.original_values ||= {}
    original_values[:client_ref_id] = support_request.client_ref_id
    original_values[:name_or_alias] = support_request.name_or_alias
    original_values[:urgency_flag]  = support_request.urgency_flag
    original_values[:eff_date]      = support_request.eff_date
    original_values[:status]        = support_request.status
    original_values[:amount]        = support_request.amount
  end

  def notate_changes
    note_text = []

    may_contain_pii = false

    original_values.each do |field, original_value|
      new_value = support_request.send(field)
      new_value = 'blank' if new_value.blank?
      original_value = 'blank' if original_value.blank?
      next unless new_value != original_value

      may_contain_pii = true if field == :name_or_alias
      note_text << "The #{field_labels[field]} for this Support Request was changed from "\
                    "#{original_value} to #{new_value}."
    end

    note_text << "Changes made by #{current_user.display_name}." if current_user
    support_request.notes.create(
      text: note_text.join("\n"),
      notable_action: "update",
      may_contain_pii: may_contain_pii
    )
  end

  def field_labels
    HashWithIndifferentAccess.new(
      amount: "Total Amount",
      client_ref_id: "Client Reference ID",
      eff_date: "Pickup Date",
      name_or_alias: "Client Alias",
      urgency_flag: "Urgency Flag",
      status: "Status",
    )
  end
end
