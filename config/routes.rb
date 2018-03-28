Students::Application.routes.draw do
  resources :students, :only => [:index, :show]

  student_check_path = "check/:lastname/:firstname/:patronymic/:group/:born_on"
  get student_check_path => "students#check", constraints: { born_on: /.+/ }

  mount API::Students => '/api'

  root to: "students#index"
end
