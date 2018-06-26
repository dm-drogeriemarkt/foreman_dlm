Rails.application.routes.draw do
  namespace :api, :defaults => { :format => 'json' } do
    scope '(:apiv)', :module => :v2,
                     :defaults => { :apiv => 'v2' },
                     :apiv => /v1|v2/,
                     :constraints => ApiConstraints.new(:version => 2, :default => true) do
      constraints(id: /[^\/]+/) do
        resources :dlmlocks, only: [:index, :show, :update, :destroy] do
          get :lock, on: :member, action: :show, controller: 'dlmlocks'
          put :lock, on: :member, action: :acquire, controller: 'dlmlocks'
          delete :lock, on: :member, action: :release, controller: 'dlmlocks'
        end
      end
      resources :dlmlocks, only: [:create]
    end
  end

  scope '/foreman_dlm' do
    resources :dlmlocks, only: [:index, :show, :destroy] do
      collection do
        get 'auto_complete_search'
      end
    end
  end
end
