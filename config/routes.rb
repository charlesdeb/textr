# frozen_string_literal: true

Rails.application.routes.draw do
  root 'text_messages#index'

  post 'text_messages/create'
  get 'text_messages/index'
  get 'text_messages/suggest'
  delete 'text_messages/reset'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
