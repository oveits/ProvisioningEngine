class SystemSetting < ActiveRecord::Base
    
    # catch any method like SystemSetting.whatever and do something with it instead of raising an error
    # found on http://stackoverflow.com/questions/185947/ruby-define-method-vs-def?rq=1
    def self.method_missing(*args)
        # assumption:
        # if we call SystemSetting.webportal_simulation_mode, we assume that the associated environment variable reads WEBPORTAL_SIMULATION_MODE (all capitals)
        environment_variable = args[0].to_s.upcase
        
        # look for database entries matching the method name, but with all capitals:
        begin
            # we need to perform the database lookup in a begin-rescue block, because rake db:migrate does not work, 
            # if the table is not yet created, but the variable is used in a spe/factories file (it seems like spec/factories is read before the actual db migration)
            foundlist =  self.where(name: environment_variable)
        rescue # e.g. ActiveRecord::StatementInvalid: Could not find table 'system_settings'
            foundlist = nil
        end

#abort environment_variable
#abort foundlist.inspect
        
        # return value, if non-ambiguous entry was found; else return environment variable, if it exists:
        if foundlist.nil?
            # foundlist is nil, if the table does not exist in the database yet (e.g. not migrated yet)
            # return the environment variable, if it exists and is "true":
            ENV[environment_variable] == "true"
        elsif foundlist.count == 1
            # found in the database: return its value as boolean
            foundlist[0].value == "true"
        elsif foundlist.count == 0 #&& !ENV[environment_variable].nil?
            # not found in the database: try to find corresponding environment variable as a fallback. 
            value = ENV[environment_variable]
            value = false if value.nil?
            
            # If found, auto-create a database entry
            @@autocreate = {} unless defined?(@@autocreate)
            @@autocreate[environment_variable] = true if @@autocreate[environment_variable].nil?
            self.new(name: environment_variable, value: value, value_type: :boolean).save! if @@autocreate[environment_variable]
            
            # return its value as boolean
            value == "true"
        elsif foundlist.count > 1
            # error handling: variable found more than once (should never happen with the right validation)
            abort "Oups, this looks like a bug: Configuration.variable with name #{environment_variable} found more than once in the database."
        else
            message = "SystemSetting: unknown error"
	    abort message
#            # error handling: variable not found:
#            message = "#{environment_variable} not found: neither in the database nor as system environment variable." +
#                      " As administrator, please create a SystemSetting variable with name #{environment_variable} " +
#                      " and the proper value (in most situations: 'true' or 'false') on the Active Admin Console on https://localhost:3000/admin/system_settings " +
#                      "(please adapt the host and port to your environment). Alternatively, restart the server. " +
#                      "This should reset the environment variable to its default value and the SystemSetting variable will be auto-created."
#            p "WARNING: " + message + "\nAuto-creating variable #{environment_variable}=\"false\""
#            ENV[environment_variable]="false"
#            false
        end # if foundlist.count == 1
    end # def self.method_missing(*args)
    
    def destroy
        # if we destroy a database entry, we do not want it to be auto-created again:
        @@autocreate = {} unless defined?(@@autocreate)
        @@autocreate[name] = false
        
        # call normal destroy prodecures:
        super
    end
    
    # prevent that a name can exist twice:
    validates :name, uniqueness: true
    
    # allow only variables with capital letters and underscores:
    validates_format_of :name, :with => /\A[A-Z0-9_\.]{1,255}\Z/, message: "needs to consist of 1 to 255 characters: A-Z, 0-9, . and/or _"

end
