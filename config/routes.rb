Rails.application.routes.draw do
  
  #root 'welcome#index'
  #root 'customers#index'
    # OV added. See http://stackoverflow.com/questions/13303695/rails-assets-path-incorrect-in-a-scoped-production-application
if ENV["WEBPORTAL_BASEURL"] == "false" || ENV["WEBPORTAL_BASEURL"].nil?
  baseURL = '/'
else
  baseURL = ENV["WEBPORTAL_BASEURL"]
end

#abort baseURL
#baseURL = '/'

scope(path: baseURL) do
  
  root 'application#root'

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  resources :text_documents

  
  # allow for a possibility to remove all provisionins using a single button press:
  # see http://stackoverflow.com/questions/21489528/unable-to-delete-all-records-in-rails-4-through-link-to
#  resources :provisionings, except: [:destroy] do
#   collection do
#     delete :removeAll
#   end
#   member do
#     delete :stop
#   end 
#  end
  
  # OV replaced by:
  #resources :customers, :sites, :users, :provisionings, except: [:destroy] do
  # only supported for customers and provisionings yet:
  resources :targets, :customers, :sites, :users, :provisionings, except: [:destroy, :update] do
   collection do
     delete :removeAll
   end 
  end

  resources :targets, :customers, :sites, :users , except: [:destroy, :update] do
    collection do
      #patch :synchronizeAll
      patch :synchronize
    end
  end

    #resources :customers
   # not tested; trying to use synchronize instead
  #resources :customers, except: [:patch] do
  resources :targets, :customers, :sites, :users do
    resources :provisionings, :member => { :deliver => :post}
    collection do
      #patch :synchronizeAll
      patch :synchronize
    end
    member do
     patch :synchronize
     patch :provision
     patch :deprovision
    end
  end
 
  
  resources :provisionings do
    member do
      put 'deliver'
    end
  end

#  not needed anymore: e.g. targets/3/customers is now replaced /customers?target_id=3; in this method, it can be used for filtering in the index
#  resources :targets do
#    resources :customers, :sites, :users
#  end

  resources :customers do
    # TODO: OV: what is needed this for?
    #get :index, :controller => :sites

    resources :sites, :users
  end

  resources :sites do
    resources :users
  end
  

  # TODO: is this needed? See http://stackoverflow.com/questions/21489528/unable-to-delete-all-records-in-rails-4-through-link-to
  resources  :provisionings, except: [:destroy] do
    member do
      delete :stop
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
end # scope(path: baseURL) do
end # Rails.application.routes.draw do
