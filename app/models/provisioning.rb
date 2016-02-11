class Validate_action < ActiveModel::Validator
  def validate(record)
    

    if record.action.nil?
      record.errors[':action'] << "Validator: record (#{record}) does not contain action"
      record.errors[:action] << "must be of the format \"variable1=value1,variable2=value2, ...\""
    else
      
      array = record.action.split(/,/).map(&:strip) unless record.action.nil?
         
      #postData = {}
  
      while array[0]
        variableValuePairArray = array.shift.split(/=/).map(&:strip)
        if variableValuePairArray.length.to_s[/^1$|^2$/]
          #postData[variableValuePairArray[0]] = variableValuePairArray[1]
        else
          record.errors[:action] << "(here: #{:action} must be of the format \"variable1=value1,variable2=value2, ...\""
          #abort 'The POST data must be of the format "variable1=value1,variable2=value2, ..."'
        end
      end # while
    end # if
  end # def
end

class Provisioning < ActiveRecord::Base

#  def deliverasynchronously(uriString="http://localhost/CloudWebPortal", httpreadtimeout=4*3600, httpopentimeout=6)
#    deliver(uriString, httpreadtimeout, httpopentimeout)
#  end
  def activeJob?
    activeJob = false   
    begin
      activeJob = Delayed::Job.find(self.delayedjob_id)
      return true
    rescue
      return false
    end
  end
  
  def deliverasynchronously(uriString=ENV["PROVISIONINGENGINE_CAMEL_URL"], httpreadtimeout=4*3600, httpopentimeout=6)
    begin # provisioning job still running
      Delayed::Job.find(delayedjob_id)
      return nil
    rescue # else
      # create a new provisioning job for the provisioning task
      
      #delayedjob = Delayed::Job.enqueue(ProvisioningJob.new(id))
      delayedjob = delay.deliver(uriString, httpreadtimeout, httpopentimeout)
      #deliver(uriString, httpreadtimeout, httpopentimeout)
          # For troubleshooting, it is sometomes better to use the two next commands instead of the delayedjob command
          #provisioningjob = ProvisioningJob.new(id)
          #provisioningjob.perform
      
      # not needed here, sinc hwere, the delayedjob IS the provisioning attribute?
      #@provisioning.update_attributes!(:delayedjob => @delayedjob)
      #update_attributes!(:delayedjob_id => delayedjob.id) unless delayedjob.nil?
      update_attribute(:delayedjob_id, delayedjob.id) unless delayedjob.nil?
      return 0
    end
  end # def createdelayedjob
  
  def actionAsHash
    # not yet tested
    # TODO: test and move to a helper or lib that can be used by targets as well
  
    # initialize
    returnHash = {}
    
    if action.is_a?(String) && action.match(/\A([^=\n]+=[^=,\n]*)([,\n]*[^=,\n]+=[^=,\n]*)*\Z/)

      # normalize:
      actionNormalized = action.gsub(/\r/, '')
      actionNormalized = actionNormalized.gsub(/^[\s]*\n/,'') # ignore empty lines
      actionNormalized = actionNormalized.gsub(/\n/, ', ')
      actionNormalized = actionNormalized.gsub(/,[\s]*\Z/, '')# remove trailing commas 

      array = actionNormalized.split(/,/)
             
      while array[0]
        variableValuePairArray = array.shift.split(/=/).map(&:strip)
            #p '+++++++++++++++++++++++++  variableValuePairArray ++++++++++++++++++++++++++++++++'
            #p variableValuePairArray.inspect
        if variableValuePairArray.length.to_s[/^2$/]
          returnHash[variableValuePairArray[0]] = variableValuePairArray[1]
        elsif variableValuePairArray.length.to_s[/^1$/]
          returnHash[variableValuePairArray[0]] = ""
        else
          abort "action (here: #{action}) must be of the format \"variable1=value1,variable2=value2, ...\""
        end
      end
    else
      abort "HttpPostRequest: wrong action (#{action.inspect}) type or format"
    end # if action.is_a?(Hash)
    
    returnHash
  end
  
  def deliver(uriStringCSV=ENV["PROVISIONINGENGINE_CAMEL_URL"], httpreadtimeout=600, httpopentimeout=6)

    uriStringArray = uriStringCSV.split(',')
    
    if defined?(@@nextUri) && uriStringCSV.match(/#{@@nextUri}/)
      # keep @@nextUri
    else
      # (re-)set @@nextUri to the first element in the array
      @@nextUri = uriStringArray[0]
    end
    
    uriString = @@nextUri
          #abort @@nextUri.inspect

    # workaround for the fact that List commands need to be sent to "http://192.168.113.104:80/show", while all other commands need to be sent to "http://192.168.113.104:80/ProvisioningEngine"
    # set uriString = "http://192.168.113.104:80/show" for List commands
    # 1) define isListCommand?
    def isListCommand?
      if action[/action[ ]*=[ ]*List /].nil?
        false
      else
        true
      end
    end
    # 2) rewrite uriString
    uriString = uriString.gsub('ProvisioningEngine', 'show') if isListCommand?
    
    begin
      # map the action of the provisioningEngine to provisioning status
      thisaction = 'provisioning' unless action[/action[ ]*=[ ]*Add /].nil?
      thisaction = 'deletion' unless action[/action[ ]*=[ ]*Delete /].nil?
      thisaction = 'reading' unless action[/action[ ]*=[ ]*Show /].nil?
      thisaction = 'reading' unless action[/action[ ]*=[ ]*List /].nil?
      thisaction = 'preparation' unless action[/action[ ]*=[ ]*PrepareSystem/].nil?
      # if not found:
      thisaction = 'unknown action' if thisaction.nil?  

      update_attribute(:status, 'started at ' + Time.now.to_s) unless thisaction == 'reading'
      provisioningRequest = HttpPostRequest.new
      
      #resulttext = provisioningRequest.perform("customerName=#{targetobject.customer.name}, action = Show Sites, SiteName=#{targetobject.name}", "http://localhost/CloudWebPortal", provisioningRequestTimeout)
  
      # shorter timeouts for read requests:
      httpreadtimeout = 15 if thisaction=='reading' 

      if attempts.nil?
        update_attribute(:attempts, 1)
      else
        update_attribute(:attempts, attempts + 1 )
      end unless thisaction == 'reading'
        
      
      # update the status of the target objects
      targetobjects = [user, site, customer, provisioningobject] # extend, if needed; highest priority first (see comment below)

      # find targetobject:
      targetobject = nil
      targetobjects.each do |targetobject_i|
        unless targetobject_i.nil? 
            #abort targetobject_i.inspect
          targetobject = targetobject_i
          break
        end
      end

      abort "Provisioning.deliver: could not find target object for provisioning" if targetobject.nil? unless thisaction == 'reading'

        # e.g. with "provisioning.action = 'Add Customer, ...', update the status of the customer object to 'provisioning in progress'"
        # only the first non-nil object is updated
	# i.e., if user is defined, then the user status is updated only
	# 	if user is nil and the site is definde, then only the status of the site is updated
	# 	if both, the user and site are nil and the customer is defined, then the customer status is updated
      targetobject.update_attribute(:status, thisaction + ' in progress') unless targetobject.nil? || thisaction == 'reading'

#abort httpreadtimeout.inspect
      resulttext = provisioningRequest.perform(action, uriString, httpreadtimeout, httpopentimeout)
      
      case thisaction
        when 'preparation'
          result = {}
          result['SSH Password Support'] = 'SSH ProvisioningEngine support added for OSV' if /added password authentication support/.match(resulttext)
          result['SSH Password Support'] = 'SSH ProvisioningEngine support was already added to OSV' if /password authentication is already supported/.match(resulttext)
          result['SSH user login'] = 'SSH access for user srx now allowed from ProvisioningEngine' if /added Web Portal to the list of allowed srx ssh hosts/.match(resulttext)
          result['SSH user login'] = 'SSH access for user srx was already allowed from ProvisioningEngine' if /Web Portal already allowed/.match(resulttext)
          peScriptVersion = resulttext.match(/version of new ProvisioningScripts.*$/).to_s.gsub('version of new ProvisioningScripts = ([^ \n]*)', '\1') unless resulttext.nil?
          result['ProvisioningScripts Version'] = "ProvisioningScripts version = #{peScriptVersion.inspect}"

          targetobject.update_attribute(:status, result.inspect)

          # TODO: preparation is work in progress and not yet tested...
                #File.open("resulttext", "w") { |file| file.write resulttext }
                #abort result.inspect
                #abort resulttext
                #existingVersion = resulttext.match(/version of existing.*$/).inspect
                #newVersion = resulttext.match(/version of new.*$/).inspect
                #updated = false if /Existing ProvisioningScripts do not need to be upgraded/.match(resulttext)
                #abort newVersion.inspect
                #abort result.inspect
        else
          case resulttext 
            when nil 
            # error: Apache Camel based CloudWebPortal does not seem to be running or is unreachable
              # for the case the BODY was empty
              resulttext = "connection timout for #{uriString} at " + Time.now.to_s
              returnvalue = 8
              targetobject.update_attribute(:status, thisaction + ' failed: ProvisioningEngine connection timeout; trying again') unless targetobject.nil? || thisaction == 'reading'
              targetobject.update_attribute(:status, thisaction + ' failed: ProvisioningEngine connection timeout') unless targetobject.nil? if thisaction == 'reading'
              # toggle uri, so the other uri will be used next time:
              if uriStringArray.count > 1
                case @@nextUri
                when uriStringArray[0]
                  @@nextUri = uriStringArray[1]
                when uriStringArray[1]
                  @@nextUri = uriStringArray[0]           
                end
                      #abort @@nextUri.inspect
              end
              abort ('provisioning.deliver: ' + resulttext) unless thisaction == 'reading'
            when /Too many open files/
#abort uriStringArray.count.inspect
#abort uriStringCSV
            #when /-----Too many open files/
            # error: Apache Camel has a resource problem.
              resulttext = "resource problems on #{uriString} at " + Time.now.to_s
              returnvalue = 11
              # toggle uri, so the other uri will be used next time:
              if uriStringArray.count > 1
                # other Apache Camel connector available
                case @@nextUri
                when uriStringArray[0]
                  @@nextUri = uriStringArray[1]
                when uriStringArray[1]
                  @@nextUri = uriStringArray[0]           
                end
                      #abort @@nextUri.inspect
                targetobject.update_attribute(:status, thisaction + ' failed: ProvisioningEngine resource problem; trying again on other Apache Camel connector') unless targetobject.nil? || thisaction == 'reading'
                abort 'provisioning.deliver: ' + resulttext + ": trying again on other Apache Camel connector: #{@@nextUri}"
              else
                # no other Apache Camel connector available
                targetobject.update_attribute(:status, thisaction + ' failed: ProvisioningEngine resource problem.') unless targetobject.nil? || thisaction == 'reading'
              end
            #when /Warnings:0    Errors:0     Syntax Errors:0/ 
            when /Errors:0     Syntax Errors:0/ 
            # success
              resulttext = 'finished successfully at ' + Time.now.to_s
              returnvalue = 0
              # update status of targetobject
              unless thisaction == 'reading'
                if thisaction == 'deletion'
                  targetobject.update_attribute(:status, thisaction + ' successful (press "Destroy" again to remove from database)') unless targetobject.nil?
                else
                  targetobject.update_attribute(:status, thisaction + ' successful') unless targetobject.nil?
                end
                #abort targetobjects.inspect unless targetobject.nil?
              end 
              #provisioning.update_attributes!(:delayedjob => nil)
              # 0
              #abort targetobjects.inspect
            when /ERROR: Variables file.*have read rights for user srx/
              returnvalue = 103
              resulttext = "ERROR[#{returnvalue.to_s}]=\" Target system has reported a missing file in ~srx/ProvisioningScripts/ccc_config.txt\nFull text:"  + resulttext
              unless thisaction == 'reading'
                targetobject.update_attribute(:status, thisaction + ' failed: target system has reported a missing file in ~srx/ProvisioningScripts/ccc_config.txt') unless targetobject.nil?
              end unless thisaction == 'reading'
	      
            when /org.apache.camel.CamelExchangeException: Cannot execute command/
            # timeout
              returnvalue = 3        
              resulttext = "ERROR[#{returnvalue.to_s}]=\" Apache Camel ProvisioningEngine cannot login as user srx: has srx access been prepared?\nFull text:"  + resulttext
              unless thisaction == 'reading'
                targetobject.update_attribute(:status, thisaction + ' failed: target system has denied access; is the target initialized correctly for usage with the ProvisioningEngine?') unless targetobject.nil?
              end unless thisaction == 'reading'
                #abort resulttext
              #abort 'provisioning.deliver: connection timout of one or more target systems'

            when /ERROR.*Connection timed out.*$|ERROR.*Network is unreachable.*$|ERROR.*Connection refused.*$|ERROR.*No route to host.*$|ERROR.*The OUT message was not received within.*$/
            # timeout
              returnvalue = 3        
              resulttext = "last unsuccessful attempt with ERROR[#{returnvalue.to_s}]=\""  + resulttext[/ERROR.*Connection timed out.*$|ERROR.*Network is unreachable.*$|ERROR.*Connection refused.*$|ERROR.*No route to host.*$|ERROR.*The OUT message was not received within.*$/] + '" at ' + Time.now.to_s
              unless thisaction == 'reading'
                targetobject.update_attribute(:status, thisaction + ' failed (timed out); trying again') unless targetobject.nil?
              end unless thisaction == 'reading'
          	    #abort resulttext
              abort 'provisioning.deliver: connection timout of one or more target systems'
            when /TEST MODE.*$/
            # test mode
              returnvalue = 4
              resulttext = "finished with success (TEST MODE [#{returnvalue.to_s}])\"" + '" at ' + Time.now.to_s
	            # Note: we do not change the targetobject status in case of a test mode query:

            when /Script aborted.*$/
            # deletion script or ccc.sh script aborted
              returnvalue = 6
              resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/Script aborted.*$/] + '" at ' + Time.now.to_s
              unless thisaction == 'reading'
                targetobject.update_attribute(:status, thisaction + ' failed (script error)') unless targetobject.nil?
              end
            when /error while loading shared libraries.*$/
            # OSV shared library export bug
              returnvalue = 7
              resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/error while loading shared libraries.*$/] + '" at ' + Time.now.to_s
              unless thisaction == 'reading'
                targetobject.update_attribute(:status, thisaction + ' failed (OSV export error)') unless targetobject.nil?
              end
              abort 'provisioning.deliver: OSV export error'
            when /ERROR.*Site.*exists already.*$|ERROR.*Customer.*exists already.*|ERROR.*phone number is in use already.*$/
            # failure: object exists already
              returnvalue = 100
              resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/Site.*exists already.*$|Customer.*exists already.*|phone number is in use already.*$/] + '" at ' + Time.now.to_s
              #resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/[^:]*exists already.*$/] + '" at ' + Time.now.to_s
              # TODO: update Site Data as seen from OSV
              unless thisaction == 'reading'
                targetobject.update_attribute(:status, thisaction + ' success: was already provisioned') unless targetobject.nil?
                p targetobject.status unless targetobject.nil?
                unless targetobject.nil?
                  updateDB = UpdateDB.new
                  updateDB.perform(targetobject) 
                end
              end unless thisaction == 'reading'
              #provisioning.update_attributes!(:delayedjob => nil)
              # TODO: update database from information read from target system
            when /ERROR.*does not exist.*$/
            # failure: object already deleted
              returnvalue = 101
              resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/ERROR.*does not exist.*$/][7,400] + '" at ' + Time.now.to_s
              unless thisaction == 'reading'
                targetobject.update_attribute(:status, thisaction + ' failed: was already de-provisioned (press "Destroy" or "Delete" again to remove from database') unless targetobject.nil?
              end
            when /Warnings/
            # import errors
              returnvalue = 5
              #resulttext = "Import ERROR[#{returnvalue.to_s}]=\"" + resulttext[/OSV.*Success.*$/] unless resulttext[/OSV.*Success.*$/].nil?
              resulttext = "Import ERROR[#{returnvalue.to_s}]=\"" + resulttext #unless resulttext[/OSV.*Success.*$/].nil?
              unless thisaction == 'reading'
                targetobject.update_attribute(:status, thisaction + ' failed (import errors)') unless targetobject.nil?
              end
              #provisioning.update_attributes!(:delayedjob => nil)
            when /xml version|<Result>/
            # show command with XML output
	      returnvalue = 9
              # keep resulttext, no status change
            else
            # failure
              returnvalue = 1
              #resulttext = "finished with unknown ERROR[#{returnvalue.to_s}]=BODY[0,1000]=\"" + resulttext[0,1000] + '" at ' + Time.now.to_s unless resulttext.nil? 
              resulttext = "finished with unknown ERROR[#{returnvalue.to_s}]=BODY=\"" + resulttext + '" at ' + Time.now.to_s unless resulttext.nil? 
              unless thisaction == 'reading' || targetobject.nil?
                #targetobject.update_attribute(:status, "#{thisaction} failed with #{resulttext.match(/ERROR.*\Z/).to_s}") unless targetobject.nil?
                if resulttext.match(/ERROR.*$/)
                  targetobject.update_attribute(:status, "#{thisaction} failed with #{resulttext.gsub('<pre>','').gsub(/#+$\n/, '').match(/ERROR.*$/).to_s} ... (click here for more info)")
			                     #abort resulttext
                else
                  # first 4 lines, if ERROR does not match:
                  #targetobject.update_attribute(:status, "#{thisaction} failed with #{resulttext.match(/\A.*$.*$.*$.*$/).to_s}")
                  targetobject.update_attribute(:status, "#{thisaction} failed with #{resulttext.split(/\r\n|\r|\n/)[1..3].join}")
			                     #abort resulttext
                end
              end
          end  # case resulttext
          
      end # case thisaction

      p '------------------resulttext------------------'
      p 'resulttext = ' + resulttext
      p 'returnvalue = ' + returnvalue.to_s
      p '------------------resulttext------------------'


      return resulttext if returnvalue == 9 && thisaction == 'reading'
      update_attribute(:status, resulttext) unless thisaction == 'reading'
      return returnvalue
    
#    rescue Exception => e
#        update_attribute(:status, e.message)
#        abort e.message if returnvalue == 3 || returnvalue == 7 || returnvalue == 8
    end

  end # def deliver
    
  def createdelayedjob  
    begin # provisioning job still running
      Delayed::Job.find(delayedjob_id)
    rescue # else
      # create a new provisioning job for the provisioning task
      
      delayedjob = Delayed::Job.enqueue(ProvisioningJob.new(id))
          # For troubleshooting, it is sometomes better to use the two next commands instead of the delayedjob command
          #provisioningjob = ProvisioningJob.new(id)
          #provisioningjob.perform
      
      # not needed here, sinc hwere, the delayedjob IS the provisioning attribute?
      #@provisioning.update_attributes!(:delayedjob => @delayedjob)
      update_attribute(:delayedjob_id, delayedjob.id)      
    end
  end # def createdelayedjob
     
  def destroydelayedjob
    begin
      # delete the background job, if it has not automatically been destroyed (e.g. a job is deleted after finish)
      @job = Delayed::Job.find(delayedjob_id)
      @job.destroy 
    rescue
      # just continue, if the job is deleted already  
    end
  end
  
  def delayedjob
    unless delayedjob_id.nil?
      Delayed::Job.find(delayedjob_id)
    else
      nil
    end
  end
  
  belongs_to :customer
  belongs_to :site
  belongs_to :user
  belongs_to :provisioningobject, :polymorphic => true
  #handle_asynchronously :deliverasynchronously
  validates_with Validate_action
end
