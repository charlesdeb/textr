# README

For more information about this project check <https://hlml.blog/2021/05/30/actual-text-prediction/> and the follow-up post.

It's a proof of concept for text prediction without using neural nets in Ruby on Rails.

It is not really intended that folks try and download and build this project themselves - more a hobby project for my own interest and blog site. Maybe I'll get round to building a [Heroku Button](https://www.heroku.com/elements/buttons) for a one-click install...

If you are interested, it's a pretty standard Rails 6 app, but it uses PostgreSQL (especially the array datatype) so you'll need to do the general Rails set-up stuff with `bundle install` and `rake db:setup`. You'll need `yarn` to be installed, and install all the packages needed for webpacker. `rails s` will run webpacker to compile the Javascript assets

Once all that's done, tests can be run with `rspec spec`, but the request specs that require a real browser might cause grief. The main guts of the application is in the models anyway - so `rspec spec/models/` is the most important part to get running.

The UI does not have a way to added new languages to the system. You'll need to do this with the rails console (`rails c`) and then run something like this for whatever language you want:

```rb
Language.create(language: 'English')
```

`database.yml` file is configured to support unicode encodings, so you should be good to use languages that don't just use the Latin alphabet.