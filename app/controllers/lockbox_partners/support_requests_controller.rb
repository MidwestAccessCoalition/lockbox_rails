require './lib/create_support_request'
require './lib/update_support_request'

class LockboxPartners::SupportRequestsController < ApplicationController
  before_action :require_admin, except: [:show, :update_status]

  def new
    if params[:lockbox_partner_id]
      @lockbox_partner = LockboxPartner.find(params[:lockbox_partner_id])
    end
    @support_request = current_user.support_requests.build
    @path = if @lockbox_partner
      lockbox_partner_support_requests_path @lockbox_partner
    else
      support_requests_path
    end
  end

  def create
    merged_params = support_request_params.merge(
      lockbox_partner_id: params[:lockbox_partner_id],
      user_id: current_user.id
    )
    result = CreateSupportRequest.call(params: merged_params)
    if result.success?
      @support_request = result.value
      redirect_to lockbox_partner_support_request_path(@support_request.lockbox_partner, @support_request)
    else
      render json: {
        error: render_to_string(
          partial: 'shared/error',
          locals: { key: 'alert', value: result.failure }
        )
      }
    end
  end

  def show
    @support_request = SupportRequest.includes(:notes).find(params[:id])
    @lockbox_partner = @support_request.lockbox_partner

    # For support request nav bar
    @newer_support_request = @support_request.newer_request_by_partner
    @newer_request_path = if @newer_support_request
      lockbox_partner_support_request_path(@lockbox_partner, @newer_support_request)
    end

    @older_support_request = @support_request.older_request_by_partner
    @older_request_path = if @older_support_request
      lockbox_partner_support_request_path(@lockbox_partner, @older_support_request)
    end
    require_admin_or_ownership
  end

  def update_status
    @support_request = SupportRequest.find(params[:support_request_id])
    @lockbox_partner = @support_request.lockbox_partner
    require_admin_or_ownership

    result = UpdateSupportRequest.call(
        support_request: @support_request,
        params: {lockbox_action_attributes: {id: @support_request.lockbox_action.id, status: update_status_params[:status]}},
        current_user: current_user
    )

    if result.success?
      flash[:notice] = "Status updated to #{update_status_params[:status]}"
    else
      flash[:error] = "Failed to update status"
    end

    redirect_back(fallback_location: lockbox_partner_support_request_path(id: @support_request.id))
  end

  def edit
    @support_request = SupportRequest
      .includes(:notes, :lockbox_transactions)
      .find(params[:id])
    @lockbox_partner = @support_request.lockbox_partner
    @path = lockbox_partner_support_request_path(@support_request)
  end

  def update
    @support_request = SupportRequest.find(params[:id])
    @lockbox_partner = @support_request.lockbox_partner

    result = UpdateSupportRequest.call(support_request: @support_request, params: support_request_params, current_user: current_user)

    if result.success?
      flash[:notice] = "Support request was successfully updated"
      redirect_to lockbox_partner_support_request_path(@support_request)
    else
      render json: {
        error: render_to_string(
          partial: 'shared/error',
          locals: { key: 'alert', value: result.failure }
        )
      }
    end
  end

  private

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
          :expense_category_id,
          :distance,
          :_destroy # Virtual attribute used to delete records
        ]
      ]
    )
  end

  def update_status_params
    params.permit(:status)
  end

end
