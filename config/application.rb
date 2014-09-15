require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# OV added according to: http://stackoverflow.com/questions/4074830/adding-lib-to-config-autoload-paths-in-rails-3-does-not-autoload-my-module
#config.autoload_paths += Dir["#{config.root}/lib/**/"]
#config.autoload_paths += Dir["/lib/**/"]

module ProvisioningPortalv4
  class Application < Rails::Application
    # OV: added (see http://urbanautomaton.com/blog/2013/08/27/rails-autoloading-hell/ for details)
    # needed to load the class ProvisioningJob from file lib/provisioning_job.rb
    config.autoload_paths << Rails.root.join("lib")
    
    # OV: added:
    config.active_record.schema_format :sql
    
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
  end
end
