Extface::Engine.routes.draw do
  resources :jobs

  resources :devices do
    resources :jobs, only: [:show]
    post :test_page, on: :member
  end
  
  get ':device_uuid' => 'handler#pull', as: :pull
  post ':device_uuid' => 'handler#push', as: :push
  root 'devices#index'
end
