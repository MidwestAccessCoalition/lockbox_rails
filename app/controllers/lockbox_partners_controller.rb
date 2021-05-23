class LockboxPartnersController < ApplicationController
  before_action :set_lockbox_partner, except: [:new, :create]

  before_action :require_admin, only: [:new, :create]
  before_action :require_admin_or_ownership, only: [:show, :edit, :update]

  ACTIONS_PER_PAGE = 20

  def new
    @lockbox_partner = LockboxPartner.new
  end

  def edit
  end

  def create
    @lockbox_partner = LockboxPartner.new(lockbox_params)
    if @lockbox_partner.save
      redirect_to @lockbox_partner, notice: 'Lockbox Partner was successfully created.'
    else
      render :new
    end
  end

  def update
    if @lockbox_partner.update(lockbox_params)
      redirect_to(
        (current_user.admin? ? @lockbox_partner : edit_lockbox_partner_path(@lockbox_partner)),
        notice: 'Contact information was successfully updated.'
      )
    else
      render :edit
    end
  end

  def show
    require_admin_or_ownership
    page_number = params.permit(:page)[:page]
    @historical_actions = @lockbox_partner.historical_actions
                                          .order(created_at: :desc)
                                          .page(page_number)
                                          .per(ACTIONS_PER_PAGE)
  end

  private

  def lockbox_params
    params.require(:lockbox_partner)
          .permit(:name, :phone_number, :phone_ext, :street_address,
                  :city, :state, :zip_code, :minimum_acceptable_balance)
  end

  def set_lockbox_partner
    @lockbox_partner = LockboxPartner.find(params[:id])
  end
end
