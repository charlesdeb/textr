# frozen_string_literal: true

Rails.application.routes.draw do
  root 'texts#index'

  get 'texts/create'
  get 'texts/index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
