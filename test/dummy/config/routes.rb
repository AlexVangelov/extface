Rails.application.routes.draw do

  mount Extface::Engine => "/shop_extface"
  resources :shops do
    unless Rails.env.development?
      extface_for :shop
    end
  end
end
