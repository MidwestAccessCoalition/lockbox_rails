Rails.application.routes.draw do
  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    registrations: 'users/registrations'
  }

  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :users, only: [:edit, :update]

  root to: 'dashboard#index'
  get 'lockbox_partners', to: 'dashboard#index'

  get 'onboarding_success', to: 'dashboard#onboarding_success'
  get 'support', to: 'dashboard#support'

  get 'admin_dashboard', to: 'admin_dashboard#index'
  scope '/admin_dashboard' do
    post 'users', to: 'admin_dashboard#create', as: 'admin_users'
  end

  match 'support_requests/new', to: 'lockbox_partners/support_requests#new', via: [:get]
  resources :support_requests, only: [:index, :create]
  get 'support_requests_export', to: 'support_requests#export', as:'support_requests_export'

  resources :lockbox_partners, only: [:new, :create, :show, :edit, :update] do
    scope module: 'lockbox_partners' do
      resources :users, only: [:new, :create, :index, :update] do
        post 'resend_invite', to: 'users#resend_invite'
      end
      resources :support_requests, except: [:index, :destroy] do
        post 'update_status', to: 'support_requests#update_status', as: 'update_status'
        resources :notes, only: [:create, :show, :edit, :update]
      end
      resource :add_cash, only: [:new, :create], controller: 'add_cash'
      resource :reconciliation, only: [:new, :create], controller: 'reconciliation'
    end
  end

  resources :lockbox_actions, only: [:update]

  match '/404', to: "errors#not_found", via: :all
  match '/500', to: "errors#internal_server_error", via: :all
end
