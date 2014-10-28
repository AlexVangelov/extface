Extface::Engine.routes.draw do
  resources :jobs

  resources :devices do
    resources :jobs, only: [:show]
    post :test_page, on: :member
    post :fiscal, on: :member
    post :raw, on: :member
  end
  
  get ':device_uuid' => 'handler#pull', as: :pull
  get ':device_uuid/settings' => 'handler#settings', as: :settings
  post ':device_uuid' => 'handler#push', as: :push
  root 'devices#index'
end
