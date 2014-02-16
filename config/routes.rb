Extface::Engine.routes.draw do
  resources :devices

  root 'sse#index'
end
