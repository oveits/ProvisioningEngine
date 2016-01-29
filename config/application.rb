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

    # base URL of the portal. This allows to run the portal on a different URL base, e.g. /developmentsystem/customers instead of /customers /default: /)
    defaultconfig["WEBPORTAL_BASEURL"] = "/"
    
    # run the webportal in simulation mode. In this mode, no Apache Camel ProvisioningEngine module is needed (default: true)
    defaultconfig["WEBPORTAL_SIMULATION_MODE"] = "true"
    
    # run the webportal in async mode. In this case, a task "bundle exec rake jobs:work" must be started (default: false)
    defaultconfig["WEBPORTAL_ASYNC_MODE"] = "false"
    
    # control, where the HTTP POST provisioning requests are sent if not in simulation mode:
    defaultconfig["PROVISIONINGENGINE_CAMEL_URL"] = "http://1.1.1.1/ProvisioningEngine"
    
    # control, whether the user can see the synchronization buttons (default: true)
    defaultconfig["WEBPORTAL_SYNCHRONIZEBUTTON_VISIBLE"] = "true"
    
    # control, whether the user can see the "synchronize all" buttons (default: true)
    defaultconfig["WEBPORTAL_SYNCHRONIZEALLBUTTON_VISIBLE"] = "true"
    
    # hide all buttons that are not active (default: true)
    defaultconfig["WEBPORTAL_PROVISIONINGOBJECTS_HIDE_INACTIVEBUTTONS"] = "true"
    
    # allow the admin user to edit provisioning tasks (default: false)
    defaultconfig["WEBPORTAL_PROVISIONINGTASKS_EDIT_VISIBLE"] = "false"
    
    # allow the admin user to delete provisioning tasks (default: false)
    defaultconfig["WEBPORTAL_PROVISIONINGTASKS_DESTROY_VISIBLE"] = "false"
    
    # control, how many lines are shown in the status of the provisioning tasks (default: 3, i.e. 4 lines are shown)
    defaultconfig["WEBPORTAL_PROVISIONINGTASKS_NUMBER_OF_VISIBLE_STATUS_LINES_MINUS_ONE"] = "3"
    
    # for synchronizeAll jobs, this variable controls, whether an abort of a single synchronize job will lead to an abort of all synchronize jobs.
    # Should be set to false in productive environments, since an an unreachable target should not stop the whole process (default: false)
    defaultconfig["WEBPORTAL_SYNCHRONIZE_ALL_ABORT_ON_ABORT"] = "false"

    # controls, whether the destroy button allows to destroy a database object, even if the object is still provisioned on a target system.
    # Should be set to "false" in production. (default: false)
    # TODO: note that of today, the controller always allows to destroy an object. The variable influences the button visibility only. To be changed in future?
    defaultconfig["WEBPORTAL_PROVISIONINGOBJECTS_DESTROY_WO_DEPROVISION"] = "false"

    # controls, whether the count of objects is visible on the sidebar. However, this is only implemented partially. Therefore, default is false.
    defaultconfig["WEBPORTAL_SIDEBAR_RELATED_COUNT_VISIBLE"] = "false"
    
    # for demo purposes in simulation mode: if "true", this will always add a customer named 'ManuallyAddedCust' with each synchronizeAll customers,
    # if it does not exist on the database already (default: false)
    defaultconfig["WEBPORTAL_SYNCHRONIZE_ALL_ALWAYS_ADD_MANUALLY_ADDED_CUSTOMER"] = "false"
    
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
    
    # OV specify, which queueing backend AvtiveJob will use:
    config.active_job.queue_adapter = :delayed_job
  end
end
