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
      update_attributes!(:delayedjob_id => delayedjob.id) unless delayedjob.nil?
      return 0
    end
  end # def createdelayedjob
  
  def deliver(uriString=ENV["PROVISIONINGENGINE_CAMEL_URL"], httpreadtimeout=600, httpopentimeout=6)
    
    begin
      p :status
      update_attributes!(:status => 'started at ' + Time.now.to_s)
      p :status
      provisioningRequest = HttpPostRequest.new
      
      #resulttext = provisioningRequest.perform("customerName=#{targetobject.customer.name}, action = Show Sites, SiteName=#{targetobject.name}", "http://localhost/CloudWebPortal", provisioningRequestTimeout)
  
      
      if attempts.nil?
        update_attributes!(:attempts => 1 )
      else
        update_attributes!(:attempts => attempts + 1 )
      end
        
      # map the action of the provisioningEngine to provisioning status
      thisaction = 'provisioning' unless action[/Add/].nil?
      thisaction = 'deletion' unless action[/Delete/].nil?
      # if not found:
      thisaction = 'unknown action' if thisaction.nil?  
      
      # update the stats uf the target objects
      targetobjects = [user, site, customer] # extend, if needed; highest priority first (see comment below)
        # e.g. with "provisioning.action = 'Add Customer, ...', update the status of the customer object to 'provisioning in progress'"
        # only the first non-nil object is updated
	# i.e., if user is defined, then the user status is updated only
	# 	if user is nil and the site is definde, then only the status of the site is updated
	# 	if both, the user and site are nil and the customer is defined, then the customer status is updated
      targetobjects.each do |targetobject|
        targetobject.update_attributes!(:status => thisaction + ' in progress') unless targetobject.nil?
        break unless targetobject.nil?
      end

      resulttext = provisioningRequest.perform(action, uriString, httpreadtimeout, httpopentimeout)
      
      case resulttext 
        when nil 
        # error: Apache Camel based CloudWebPortal does not seem to be running or is unreachable
          # for the case the BODY was empty
          resulttext = "connection timout for #{uriString} at " + Time.now.to_s
          returnvalue = 8
          targetobjects.each do |targetobject|
            targetobject.update_attributes!(:status => thisaction + ' failed: ProvisioningEngine connection timeout; trying again') unless targetobject.nil?
            break unless targetobject.nil?
          end
          abort 'provisioning.deliver: ' + resulttext
        when /Warnings:0    Errors:0     Syntax Errors:0/ 
        # success
          resulttext = 'finished successfully at ' + Time.now.to_s
          returnvalue = 0
          # update status of targetobject
          targetobjects.each do |targetobject|
            if thisaction == 'deletion'
              targetobject.update_attributes!(:status => thisaction + ' successful (press "Destroy" again to remove from database)') unless targetobject.nil?
            else
              targetobject.update_attributes!(:status => thisaction + ' successful') unless targetobject.nil?
            end
            break unless targetobject.nil?
            #abort targetobjects.inspect unless targetobject.nil?
          end
          #provisioning.update_attributes!(:delayedjob => nil)
          # 0
          #abort targetobjects.inspect
        when /ERROR.*Connection timed out.*$|ERROR.*Network is unreachable.*$|ERROR.*Connection refused.*$/
        # timeout
          returnvalue = 3        
          resulttext = "last unsuccessful attempt with ERROR[#{returnvalue.to_s}]=\""  + resulttext[/ERROR.*Connection timed out.*$|ERROR.*Network is unreachable.*$|ERROR.*Connection refused.*$/] + '" at ' + Time.now.to_s
          targetobjects.each do |targetobject|
            targetobject.update_attributes!(:status => thisaction + ' failed (timed out); trying again') unless targetobject.nil?
            break unless targetobject.nil?
          end
          abort 'provisioning.deliver: connection timout of one or more target systems'
        when /TEST MODE.*$/
        # test mode
          returnvalue = 4
          resulttext = "finished with success (TEST MODE [#{returnvalue.to_s}])\"" + '" at ' + Time.now.to_s
	# do not change the status in case of a test mode query:
#          targetobjects.each do |targetobject|
#            targetobject.update_attributes!(:status => thisaction + ' successful (test mode)') unless targetobject.nil?
#            break unless targetobject.nil? 
#          end
          #provisioning.update_attributes!(:delayedjob => nil)
        when /Script aborted.*$/
        # deletion script or ccc.sh script aborted
          returnvalue = 6
          resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/Script aborted.*$/] + '" at ' + Time.now.to_s
          targetobjects.each do |targetobject|
            targetobject.update_attributes!(:status => thisaction + ' failed (script error)') unless targetobject.nil?
            break unless targetobject.nil?
          end
        when /error while loading shared libraries.*$/
        # OSV shared library export bug
          returnvalue = 7
          resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/error while loading shared libraries.*$/] + '" at ' + Time.now.to_s
          targetobjects.each do |targetobject|
            targetobject.update_attributes!(:status => thisaction + ' failed (OSV export error)') unless targetobject.nil?
            break unless targetobject.nil?       
          end
          abort 'provisioning.deliver: OSV export error'
        #when /ERROR.*Site Name .* exists already.*$|ERROR.*Customer.*exists already.*|ERROR.*phone number is in use already.*$/
        when /ERROR.*Site.*exists already.*$|ERROR.*Customer.*exists already.*|ERROR.*phone number is in use already.*$/
        # failure: object exists already
          returnvalue = 100
          resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/Site.*exists already.*$|Customer.*exists already.*|phone number is in use already.*$/] + '" at ' + Time.now.to_s
          #resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/[^:]*exists already.*$/] + '" at ' + Time.now.to_s
          # TODO: update Site Data as seen from OSV
          targetobjects.each do |targetobject|
            targetobject.update_attributes!(:status => thisaction + ' success: was already provisioned') unless targetobject.nil?
            p targetobject.status unless targetobject.nil?
            unless targetobject.nil?
              updateDB = UpdateDB.new
              updateDB.perform(targetobject) 
            end
            break unless targetobject.nil? 
          end
          #provisioning.update_attributes!(:delayedjob => nil)
          # TODO: update database from information read from target system
        when /ERROR.*does not exist.*$/
        # failure: object already deleted
          returnvalue = 101
          resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/ERROR.*does not exist.*$/][7,400] + '" at ' + Time.now.to_s
          targetobjects.each do |targetobject|
            targetobject.update_attributes!(:status => thisaction + ' failed: was already de-provisioned') unless targetobject.nil?
            # instead of updating the status, remove from database (can be commented out)
	    # now to be done in the controller on returnvalue 101 (implemented for customer only)
            unless targetobject.nil?
p targetobject.inspect
              targetobject.destroy unless targetobject == customer
              break
            end 
          end 
        when /Warnings/
        # import errors
          returnvalue = 5
          resulttext = "Import ERROR[#{returnvalue.to_s}]=\"" + resulttext[/OSV.*Success.*$/] unless resulttext[/OSV.*Success.*$/].nil?
          targetobjects.each do |targetobject|
            targetobject.update_attributes!(:status => thisaction + ' failed (import errors)') unless targetobject.nil?
            break unless targetobject.nil?
          end
          #provisioning.update_attributes!(:delayedjob => nil)
        else
        # failure
          returnvalue = 1
          resulttext = "finished with unknown ERROR[#{returnvalue.to_s}]=BODY[0,400]=\"" + resulttext[0,400] + '" at ' + Time.now.to_s unless resulttext.nil? 
          targetobjects.each do |targetobject|
            targetobject.update_attributes!(:status => thisaction + ' failed') unless targetobject.nil?
            break unless targetobject.nil? 
          end
      end  # case resulttext
  
      p '------------------resulttext------------------'
      p 'resulttext = ' + resulttext
      p 'returnvalue = ' + returnvalue.to_s
      p '------------------resulttext------------------'
         
      update_attributes!(:status => resulttext)
      return returnvalue
    
#    rescue Exception => e
        update_attributes!(:status => e.message)
        abort e.message if returnvalue == 3 || returnvalue == 7 || returnvalue == 8
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
      update_attributes!(:delayedjob_id => delayedjob.id)      
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
  #handle_asynchronously :deliverasynchronously
  validates_with Validate_action
end
