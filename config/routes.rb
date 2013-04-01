Students::Application.routes.draw do
  resources :students, :only => [:index, :show]

  get "check/:lastname/:firstname/:patronymic/:group/:born_on" => "students#check", :constraints => { :born_on => /.+/ }

  mount API::Students => '/api'

  root :to => "students#index"
end
