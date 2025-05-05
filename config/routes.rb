Rails.application.routes.draw do
  post '/notifications', to: 'notifications#create'
end
