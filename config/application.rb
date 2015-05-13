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
    #config.active_record.schema_format :sql
    
    # OV added. See http://stackoverflow.com/questions/13303695/rails-assets-path-incorrect-in-a-scoped-production-application
    if ENV["WEBPORTAL_BASEURL"] == "false" || ENV["WEBPORTAL_BASEURL"].nil? || /^\/$/.match(ENV["WEBPORTAL_BASEURL"])
      baseURL = '/assets'
    else
      baseURL = ENV["WEBPORTAL_BASEURL"] + '/assets'
    end
    config.assets.prefix = baseURL #'/assets'

    # OV added (see http://stackoverflow.com/questions/23123586/no-route-matches-get-stylesheets-frontend-css)
    config.assets.precompile += %w( main.css )
    config.assets.precompile += %w( application.css )
    
    defaultconfig = {}

    # control, where the HTTP POST provisioning requests are sent if not in simulation mode:
    defaultconfig["PROVISIONINGENGINE_CAMEL_URL"] = "http://1.1.1.1/ProvisioningEngine"
    
    # run the webportal in simulation mode. In this mode, no Apache Camel ProvisioningEngine module is needed (default: true)
    defaultconfig["WEBPORTAL_SIMULATION_MODE"] = "true"
    
    # run the webportal in async mode. In this case, a task "bundle exec rake jobs:work" must be started (default: false)
    defaultconfig["WEBPORTAL_ASYNC_MODE"] = "false"
    
    # control, whether the user can see the synchronization button (default: true)
    defaultconfig["WEBPORTAL_SYNCHRONIZEBUTTON_VISIBLE"] = "true"
    
    # hide all buttons that are not active (default: true)
    defaultconfig["WEBPORTAL_PROVISIONINGOBJECTS_HIDE_INACTIVEBUTTONS"] = "true"
    
    # base URL of the portal. This allows to run the portal on a different URL base, e.g. /developmentsystem/customers instead of /customers /default: /)
    defaultconfig["WEBPORTAL_BASEURL"] = "/"
    
    # allow the admin user to edit provisioning tasks (default: false)
    defaultconfig["WEBPORTAL_PROVISIONINGTASKS_EDIT_VISIBLE"] = "false"
    
    # allow the admin user to delete provisioning tasks (default: false)
    defaultconfig["WEBPORTAL_PROVISIONINGTASKS_DESTROY_VISIBLE"] = "false" 
    
    # set default values for environment variables that are not yet set:
    defaultconfig.each do |key, value| 
      ENV[key.to_s] = value if ENV[key.to_s].nil?   
    end 
      
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
