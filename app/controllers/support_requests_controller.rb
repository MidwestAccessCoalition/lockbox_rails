require './lib/create_support_request'

class SupportRequestsController < ApplicationController
  before_action :require_admin, except: [:create]

  def index
    @support_requests = SupportRequest.includes(:lockbox_partner, :user).pending.order("created_at desc")
  end

  def create
    merged_params = support_request_params.merge(user_id: current_user.id)
    result = CreateSupportRequest.call(params: merged_params)

    if result.success?
      @support_request = result.value
      partner = @support_request.lockbox_partner
      add_insufficient_funds_alert if partner.insufficient_funds?
      redirect_to lockbox_partner_support_request_path(partner, @support_request)
    else
      render json: {
        error: render_to_string(
          partial: 'shared/error',
          locals: { key: 'alert', value: result.failure }
        )
      }
    end
  end

  def export
    respond_to do |format|
      format.html
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=support_requests-#{Date.today}.csv"
        send_data SupportRequest.to_csv, filename: "support_requests-#{Date.today}.csv"
      end
    end
  end

  private

  def add_insufficient_funds_alert
    flash[:alert] = %(
      The Pending Support Requests exceed your Lockbox balance. If more funds
      are not already on the way, please reach out to your lockbox manager at
      #{ENV['LOCKBOX_EMAIL']}.
    ).strip
  end

  def support_request_params
    params.require(:support_request).permit(
      :client_ref_id,
      :name_or_alias,
      :urgency_flag,
      :lockbox_partner_id,
      lockbox_action_attributes: [
        :id,
        :eff_date,
        lockbox_transactions_attributes: [
          :id,
          :amount,
          :category,
          :distance,
          :_destroy # Virtual attribute used to delete records
        ]
      ]
    )
  end

end
