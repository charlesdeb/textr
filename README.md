# README

For more information about this project check <https://hlml.blog/2021/05/30/actual-text-prediction/>

It's a proof of concept for text prediction without using neural nets in Ruby on Rails.

It is not really intended that folks try and download and build this project themselves - more a hobby project for my own interest and blog site.

If you are interested, it's a pretty standard Rails 6 app, but it uses PostgreSQL (especially the array datatype) so you'll need to do the general Rails set-up stuff with `bundle install` and `rake db:setup`.

Once all that's done, tests can be run with `rspec spec`, but the request specs that require a real browser might cause grief. The main guts of the application is in the models anyway - so `rspec spec/models/` is the most important part to get running.
