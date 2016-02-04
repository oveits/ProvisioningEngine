class Config < ActiveRecord::Base
    
    # catch any method like Config.whatever and do something with it instead of raising an error
    # found on http://stackoverflow.com/questions/185947/ruby-define-method-vs-def?rq=1
    def self.method_missing(*args)
        # assumption:
        # if we call Config.webportal_simulation_mode, we assume that the associated environment variable reads WEBPORTAL_SIMULATION_MODE (all capitals)
        environment_variable = args[0].to_s.upcase
        
        # look for database entries matching the method name, but with all capitals:
        foundlist =  Config.where(name: environment_variable)
        
        # return value, if non-ambiguous entry was found; else return environment variable, if it exists:
        if foundlist.count == 1
            # found in the database: return its value as boolean
            foundlist[0].value == "true"
        elsif foundlist.count == 0 && !ENV[environment_variable].nil?
            # not found in the database: try to find corresponding environment variable as a fallback. 
            value = ENV[environment_variable]
            
            # If found, auto-create a database entry
            Config.new(name: environment_variable, value: value, value_type: :boolean).save!
            
            # return its value as boolean
            value == "true"
        elsif foundlist.count > 1
            # error handling: variable found more than once (should never happen with the right validation)
            abort "Oups, this looks like a bug: Config.variable with name #{environment_variable} found more than once in the database."
        else
            # error handling: variable not found:
            abort "#{environment_variable} not found: neither in the database nor as system environment variable"
        end # if foundlist.count == 1
    end # def self.method_missing(*args)
    
    def destroy
        # if we destroy a database entry, we need to remove the environment variable first in order to prevent it from being auto-created immediately.
        ENV[self.name] = nil
        
        # call normal destroy prodecures:
        super
    end
    
    # prevent that a name can exist twice:
    validates :name, uniqueness: true
    
    # allow only variables with capital letters and underscores:
    validates_format_of :name, :with => /\A[A-Z0-9_]{1,255}\Z/, message: "needs to consist of 1 to 255 characters: A-Z, 0-9 and/or _"
    
end
