class LockboxActionsController < ApplicationController
  before_action :find_lockbox_action, only: [:update]
  before_action :require_ownership

  def update
    if @lockbox_action.update(update_params)
      flash[:notice] = "Success!"
      redirect_to lockbox_partners_path
    else
      flash[:alert] = "Sorry, there was a problem."
      redirect_to lockbox_partners_path
    end
  end

  private

  def find_lockbox_action
    @lockbox_action = LockboxAction.find(params[:id])
  end

  def update_params
    params.require(:lockbox_action).permit(:status)
  end

  def require_ownership
    if !current_user.admin? && current_user.lockbox_partner != @lockbox_action.lockbox_partner
      return redirect_to root_path
    end
  end
end
