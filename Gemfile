source 'https://rubygems.org'
ruby '2.1.3'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.4'
group :development, :test do
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3'
  gem 'rspec-rails', '2.13.1'
end

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# OV: temporarily commented out because bundle install did not work:
#gem 'debugger', group: [:development, :test]

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin]

# OV added:
#gem 'ruby-debug-base' 
#gem 'ruby-debug-ide'

# OV added:
gem 'delayed_job_active_record'

gem "delayed_job_web"

# OV for making synchronous calls to provisioning.deliver non-blocking:
# note: this requires curl to be installed. See 
#gem 'typhoeus'
#gem 'ethon'

gem 'em-http-request'

# OV needed for JRuby, see https://devcenter.heroku.com/articles/moving-an-existing-rails-app-to-run-on-jruby
#ruby '1.9.3', :engine => 'jruby', :engine_version => '1.7.1'
#ruby '1.9.3', :engine => 'jruby', :engine_version => '1.7.1'
#gem 'puma'
# or alternatively, but has higher memory footprint: 
# gem 'trinidad'

# OV: needed for heroku (see https://www.railstutorial.org/book/beginning#sec-heroku_setup)
group :production do
  gem 'pg', '0.15.1'
  gem 'rails_12factor', '0.0.2'
end

gem 'seed_dump'

group :test do
  gem 'selenium-webdriver', '2.35.1'
  gem 'capybara', '2.1.0'
  # OV to get rid of a warining during running 
  gem "minitest"
end

# OV for speeding up rspec test startup:
group :development, :test do
  gem 'spork-rails', '4.0.0'
  gem 'guard-spork', '1.5.0'
  #gem 'childprocess', '0.3.6'
end

# OV: pre-populate the test database
group :test do
  gem 'factory_girl_rails', '4.2.0'
end

gem 'figaro'
#gem "figaro", "~> 0.7.0"
