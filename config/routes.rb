Rails.application.routes.draw do
  
  #root 'welcome#index'
  #root 'customers#index'
  
  root 'application#root'
 
  resources :targets do
    resources :customers
  end
  

  resources :users do
    resources :provisionings, :member => { :deliver => :post}
    member do
     #patch :synchronize
     patch :provision
    end 
  end

  # allow for a possibility to remove all provisionins using a single button press:
  # see http://stackoverflow.com/questions/21489528/unable-to-delete-all-records-in-rails-4-through-link-to
  resources :provisionings, except: [:destroy] do
   collection do
     delete :removeAll
   end
   member do
     delete :stop
   end 
  end
  
  resources :provisionings do
    member do
      put 'deliver'
    end
  end

  resources :sites do
    resources :sites, :users
    resources :provisionings, :member => { :deliver => :post}
    member do
     patch :synchronize
     patch :provision
    end 
  end
  
  #resources :customers
    
  # OV replaced by:
  resources :customers, except: [:destroy] do
   collection do
     delete :removeAll
   end 
  end
  
  resources :customers do
    resources :sites, :users
    get :index, :controller => :sites
    resources :provisionings, :member => { :deliver => :post}
    member do
     patch :synchronize
     patch :provision
    end
  end
 
 #require 'delayed_job_web'
 match "/delayed_job" => DelayedJobWeb, :anchor => false, via: [:get, :post]



  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  #root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
