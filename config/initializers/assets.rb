# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

# OV added, because of an error message, after I had added <%= stylesheet_link_tag "main" %> to apps/views/layouts/application.html.erb
Rails.application.config.assets.precompile += %w( main.css )
#Rails.application.config.assets.precompile += %w( stdtheme.css )
#Rails.application.config.assets.precompile += %w( cake.generic.css )
