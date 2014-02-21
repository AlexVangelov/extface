Rails.application.routes.draw do

  mount Extface::Engine => "/shop_extface"
  resources :shops do
    extface_for :shop
  end
end
