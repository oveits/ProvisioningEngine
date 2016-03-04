source 'https://rubygems.org'
#ruby '2.1.3'
# >= is not supported in tis context:
#ruby ENV['CUSTOM_RUBY_VERSION'] || '>= 2.0.0'
# commented out again and we set the ruby version externally, e.g. in .travis.yml etc.
#ruby ENV['CUSTOM_RUBY_VERSION'] || '2.0.0'
#ruby ENV['CUSTOM_RUBY_VERSION'] || '2.2.4'

gem 'devise'
gem 'activeadmin', '1.0.0.pre2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.4'
gem 'bootstrap-sass'
group :development, :test do
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3'
  #gem 'rspec-core'
  gem 'rspec-rails', '>= 2.13.1'
  gem 'rspec-its'
  gem 'byebug'
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
gem 'jquery-turbolinks'
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
gem 'activemodel-globalid'
#gem 'activejob'
gem 'delayed_job_active_record'
#gem 'delayed_job_active_record', '~> 4.0.6'
#gem 'delayed_job_active_record','4.0.6' #, '4.0.6' #, '4.1.1'

gem "delayed_job_web", '1.2.5'

# OV added to be able to start rake jobs:work as daemon:
gem "daemons"

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
  gem 'capybara' #, '~> 2.1.0'
  # OV to get rid of a warning during running 
  gem "minitest"
  # OV was needed after upgrade to ruby v2.2.4 (see https://github.com/rspec/rspec-rails/issues/1273 or https://github.com/rails/rails/issues/18572):
  gem 'test-unit'
end

# OV for speeding up rspec test startup:
group :development, :test do
  gem 'spork-rails', '4.0.0'
  #gem 'guard-spork', '1.5.0'
  #gem 'childprocess', '0.3.6'
end

# OV: pre-populate the test database
group :test do
  gem 'factory_girl_rails', '4.2.0'
end

gem 'figaro'
#gem "figaro", "~> 0.7.0"

# OV does not work (introduces wrong path to /javascripts/respond.js instead of /assets/respond.js and even /assets/respond.js is not installed...); see https://github.com/RouL/respond-js-rails
#gem 'respond-js-rails'
# may be better? See https://github.com/gevans/respond-rails:
gem "respond-rails", "~> 1.0"

# OV for automatic creation of UML-like class diagrams (see http://rails-erd.rubyforge.org/)
# comment out only, if you want to create the ERD.PDF UML file:
#group :development do
  #gem "rails-erd" if ENV["DOCKER"].nil?
#end

gem 'activesupport'

gem 'kaminari'

# does not follow redirects, therefore cannot be used here:
#gem 'rawler'

# better than rawler?
# I had some trouble to install link-checker: it has me required to remove gem capybara first, then 'sudo apt-get install libxslt-dev libxml2-dev', then 'gem install nokogiri -v '1.5.11'', then re-add capybara and 'bundle install':
# see e.g. https://github.com/sparklemotion/nokogiri.org-tutorials/blob/8c8175021a09ff39285f558a3d435076ba624c72/content/installing_nokogiri.md
# OV: does not find any broken links it seems:
#gem 'link-checker'
# best soluton so far (see http://stackoverflow.com/questions/5403708/testing-for-broken-links-in-a-rails-application)
# wget --spider -r -l 1 --header='User-Agent: Mozilla/5.0' http://example.com 2>&1 | grep -B 2 '404'
# and
# wget --spider -r -l 1 --header='User-Agent: Mozilla/5.0' http://example.com 2>&1 | grep -B 2 '500'
