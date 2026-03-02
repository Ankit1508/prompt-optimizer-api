Rails.application.routes.draw do
  namespace :api do
    post "/optimize", to: "optimize#optimize"
  end
end
