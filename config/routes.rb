# frozen_string_literal: true

Rails.application.routes.draw do
  root 'text_messages#index'

  post 'text_messages/create'
  get 'text_messages/index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
