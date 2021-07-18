module LockboxPartnersHelper
  def days_since_last_reconciliation
    (Date.current - @lockbox_partner.reconciliation_interval_start).to_i
  end

  def status_display_text(status, support_request)
    icon_html = if status == support_request.status
      "<i class='fa fa-check'></i>"
    else
      "<i class='icon-spacer'></i>"
    end
    (icon_html + " " + status.capitalize).html_safe
  end

  def alert_display_header_class(lockbox_partner)
    return unless lockbox_partner.low_balance?
    alert_level = lockbox_partner.insufficient_funds? ? "danger" : "warning"
    "alert-#{alert_level} border border-#{alert_level}"
  end

  def display_table_top_border(lockbox_partner)
    return 'table-top-border' if !lockbox_partner.low_balance?
  end
end
