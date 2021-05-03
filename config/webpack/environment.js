const { environment } = require('@rails/webpacker');

// https://blog.andreyuhai.com/2021/03/03/how-to-add-bootstrap-to-rails-6

const webpack = require('webpack');
environment.plugins.append(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Rails: '@rails/ujs',
  })
);

module.exports = environment;
