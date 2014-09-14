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
  
  def deliverasynchronously(uriString="http://localhost/CloudWebPortal", httpreadtimeout=4*3600, httpopentimeout=6)
    begin # provisioning job still running
      Delayed::Job.find(delayedjob)
    rescue # else
      # create a new provisioning job for the provisioning task
      
      #delayedjob = Delayed::Job.enqueue(ProvisioningJob.new(id))
      delayedjob = delay.deliver(uriString, httpreadtimeout, httpopentimeout)
          # For troubleshooting, it is sometomes better to use the two next commands instead of the delayedjob command
          #provisioningjob = ProvisioningJob.new(id)
          #provisioningjob.perform
      
      # not needed here, sinc hwere, the delayedjob IS the provisioning attribute?
      #@provisioning.update_attributes(:delayedjob => @delayedjob)
      update_attributes(:delayedjob => delayedjob)      
    end
  end # def createdelayedjob
  
  def deliver(uriString="http://localhost/CloudWebPortal", httpreadtimeout=600, httpopentimeout=6)
    
    begin
      update_attributes(:status => 'started at ' + Time.now.to_s)
      provisioningRequest = HttpPostRequest.new
      
      #resulttext = provisioningRequest.perform("customerName=#{targetobject.customer.name}, action = Show Sites, SiteName=#{targetobject.name}", "http://localhost/CloudWebPortal", provisioningRequestTimeout)
  
      resulttext = provisioningRequest.perform(action, uriString, httpreadtimeout, httpopentimeout)
      
      if attempts.nil?
        update_attributes(:attempts => 1 )
      else
        update_attributes(:attempts => attempts + 1 )
      end
        
      # map the action of the provisioningEngine to provisioning status
      thisaction = 'provisioning' unless action[/Add/].nil?
      thisaction = 'deletion' unless action[/Delete/].nil?
      # if not found:
      thisaction = 'unknown action' if thisaction.nil?  
      
      targetobjects = [user, site, customer] # extend, if needed
      
      # update the stats uf the target objects
      #   e.g. with "provisioning.action = 'Add Customer, ...', update the status of the customer object to 'provisioning in progress'"
      targetobjects.each do |targetobject|
        targetobject.update_attributes(:status => thisaction + ' in progress') unless targetobject.nil?
        # only update User, if User, Site and Customer are defined. Only Update Site, if Site and Customer is defined.
        break unless targetobject.nil?
      end
      
      
      case resulttext 
        when nil 
        # unknown error
          # for the case the BODY was empty
          resulttext = 'finished with unknown error (could not retrieve BODY) at ' + Time.now.to_s
          returnvalue = 8
          targetobjects.each do |targetobject|
            targetobject.update_attributes(:status => thisaction + ' failed (unknown error); stopped') unless targetobject.nil?
            break unless targetobject.nil?
          end 
        when /Warnings:0    Errors:0     Syntax Errors:0/ 
        # success
          resulttext = 'finished successfully at ' + Time.now.to_s
          returnvalue = 0
          # update status of targetobject
          targetobjects.each do |targetobject|
            if thisaction == 'deletion'
              targetobject.update_attributes(:status => thisaction + ' successful (rerun destroy to remove from database)') unless targetobject.nil?
            else
              targetobject.update_attributes(:status => thisaction + ' successful') unless targetobject.nil?
            end
            break unless targetobject.nil?
            #abort targetobjects.inspect unless targetobject.nil?
          end
          #provisioning.update_attributes(:delayedjob => nil)
          # 0
          #abort targetobjects.inspect
        when /ERROR.*Connection timed out.*$|ERROR.*Network is unreachable.*$|ERROR.*Connection refused.*$/
        # timeout
          returnvalue = 3        
          resulttext = "last unsuccessful attempt with ERROR[#{returnvalue.to_s}]=\""  + resulttext[/ERROR.*Connection timed out.*$|ERROR.*Network is unreachable.*$|ERROR.*Connection refused.*$/] + '" at ' + Time.now.to_s
          targetobjects.each do |targetobject|
            targetobject.update_attributes(:status => thisaction + ' failed (timed out); trying again') unless targetobject.nil?
            break unless targetobject.nil?
          end
          abort 'ProvisioningJob.perform: connection timout'
        when /TEST MODE.*$/
        # test mode
          returnvalue = 4
          resulttext = "finished with success (TEST MODE [#{returnvalue.to_s}])\"" + '" at ' + Time.now.to_s
          targetobjects.each do |targetobject|
            targetobject.update_attributes(:status => thisaction + ' successful (test mode)') unless targetobject.nil?
            break unless targetobject.nil? 
          end
          #provisioning.update_attributes(:delayedjob => nil)
        when /Script aborted.*$/
        # deletion script or ccc.sh script aborted
          returnvalue = 6
          resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/Script aborted.*$/] + '" at ' + Time.now.to_s
          targetobjects.each do |targetobject|
            targetobject.update_attributes(:status => thisaction + ' failed (script error)') unless targetobject.nil?
            break unless targetobject.nil?
          end
        when /error while loading shared libraries.*$/
        # OSV shared library export bug
          returnvalue = 7
          resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/error while loading shared libraries.*$/] + '" at ' + Time.now.to_s
          targetobjects.each do |targetobject|
            targetobject.update_attributes(:status => thisaction + ' failed (OSV export error)') unless targetobject.nil?
            break unless targetobject.nil?       
          end
          abort 'ProvisioningJob.perform: OSV export error'
        when /ERROR.*Site Name .* exists already.*$|ERROR.*Customer.*exists already.*$/
        # failure: object exists already
          returnvalue = 100
          resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/Site Name .* exists already.*$|Customer.*exists already.*$/] + '" at ' + Time.now.to_s
          # TODO: update Site Data as seen from OSV
          targetobjects.each do |targetobject|
            targetobject.update_attributes(:status => thisaction + ' failed: was already provisioned') unless targetobject.nil?
            unless targetobject.nil?
              updateDB = UpdateDB.new
              updateDB.perform(targetobject) 
            end
            break unless targetobject.nil? 
          end
          #provisioning.update_attributes(:delayedjob => nil)
          # TODO: update database from information read from target system
        when /ERROR.*does not exist.*$/
        # failure: object already deleted
          returnvalue = 101
          resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/ERROR.*does not exist.*$/][7,400] + '" at ' + Time.now.to_s
          targetobjects.each do |targetobject|
            targetobject.update_attributes(:status => thisaction + ' failed: was already de-provisioned') unless targetobject.nil?
            # instead of updating the status, remove from database (can be commented out)
            unless targetobject.nil?
              targetobject.destroy
              break
            end 
          end 
        when /Warnings/
        # import errors
          returnvalue = 5
          resulttext = "Import ERROR[#{returnvalue.to_s}]=\"" + resulttext[/OSV.*Success.*$/] unless resulttext[/OSV.*Success.*$/].nil?
          targetobjects.each do |targetobject|
            targetobject.update_attributes(:status => thisaction + ' failed (import errors)') unless targetobject.nil?
            break unless targetobject.nil?
          end
          #provisioning.update_attributes(:delayedjob => nil)
        else
        # failure
          returnvalue = 1
          resulttext = "finished with unknown ERROR[#{returnvalue.to_s}]=BODY[0,400]=\"" + resulttext[0,400] + '" at ' + Time.now.to_s unless resulttext.nil? 
          targetobjects.each do |targetobject|
            targetobject.update_attributes(:status => thisaction + ' failed') unless targetobject.nil?
            break unless targetobject.nil? 
          end
      end  # case resulttext
  
      p '------------------resulttext------------------'
      p 'resulttext = ' + resulttext
      p 'returnvalue = ' + returnvalue.to_s
      p '------------------resulttext------------------'
         
      update_attributes(:status => resulttext)
      return returnvalue
    
    rescue Exception => e
        update_attributes(:status => e.message)
        abort e.message if returnvalue == 3 || returnvalue == 7 
    end

  end # def deliver
  
  def deliverOld
    # is sending provisioning.action as a HTTP POST to http://localhost/CloudWebPortal
    # Input: provisiongin.action="param1=value1, param2=value2, ..." 
    #
    # TODO: move code to ProvisioningJob (lib/provisioning_job.rb)
    # advantage: the case block can be consolidated, if everything is in the ProvisioningJob


    httpopentimeout = 5
    httpreadtimeout = 4*3600 # allow for 4 hours for deletion of large customer bases
    
  
    update_attributes(:status => 'started at ' + Time.now.to_s)

    require "net/http"
    require "uri"
    
    uri = URI.parse("http://localhost/CloudWebPortal")
    
    #response = Net::HTTP.post_form(uri, {"testMode" => "testMode", "offlineMode" => "offlineMode", "action" => "Add Customer", "customerName" => @customer.name})
    #OV replaced by (since I want to control the timers):
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = httpopentimeout
    http.read_timeout = httpreadtimeout
    request = Net::HTTP::Post.new(uri.request_uri)

    array = action.split(/,/).map(&:strip)
    
    postData = {}

    while array[0]
      variableValuePairArray = array.shift.split(/=/).map(&:strip)
      if variableValuePairArray.length.to_s[/^2$/]
        postData[variableValuePairArray[0]] = variableValuePairArray[1]
      elsif variableValuePairArray.length.to_s[/^1$/]
        postData[variableValuePairArray[0]] = ""
      else
        abort "action (here: #{:action}) must be of the format \"variable1=value1,variable2=value2, ...\""
      end
    end
    
    p '------------------------------'
    p postData.inspect
    p '------------------------------'
    
    request.set_form_data(postData)
    
    begin
      #sleep 20
      #httpThread = Thread.new { response = http.request(request) }
      #httpThread = Thread.new { sleep 20, response = 'timeout' }
      response = http.request(request)
      #sleep httpreadtimeout + httpopentimeout
      #httpThread.join
      #response = 'timeout'
      responseBody = response.body
    rescue Exception=>e
#      sleep 20
      responseBody = 'ERROR: Provisioning Engine: Connection timed out'
#      update_attributes(:status => 'last unsuccessful attempt with ERROR="' + resulttext + '" at ' + Time.now.to_s)
#      return 3
      #abort resulttext
    end
    
      #
      # retrieve resulttext
      #
    resulttext = nil if responseBody.nil?

    resulttext = responseBody #[0..400]  
    
    case resulttext
      when nil
        # for the case the BODY was empty
        resulttext = 'finished with unknown error (could not retrieve BODY) at ' + Time.now.to_s
        returnvalue = 1
      when /Warnings:0    Errors:0     Syntax Errors:0/
        resulttext = 'finished successfully at ' + Time.now.to_s
        returnvalue = 0
      when /ERROR.*Connection timed out.*$|ERROR.*Network is unreachable.*$|ERROR.*Connection refused.*$/
        returnvalue = 3        
        resulttext = "last unsuccessful attempt with ERROR[#{returnvalue.to_s}]=\""  + resulttext[/ERROR.*Connection timed out.*$|ERROR.*Network is unreachable.*$|ERROR.*Connection refused.*$/] + '" at ' + Time.now.to_s
      when /TEST MODE.*$/
        returnvalue = 4
        resulttext = "finished with success (TEST MODE [#{returnvalue.to_s}])\"" + '" at ' + Time.now.to_s
      when /Script aborted.*$/
        returnvalue = 6
        resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/Script aborted.*$/] + '" at ' + Time.now.to_s
      when /error while loading shared libraries.*$/
        returnvalue = 7
        resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/error while loading shared libraries.*$/] + '" at ' + Time.now.to_s
      when /ERROR.*Site Name .* exists already.*$|ERROR.*Customer.*exists already.*$/
        returnvalue = 100
        resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/Site Name .* exists already.*$|Customer.*exists already.*$/] + '" at ' + Time.now.to_s
        # TODO: update Site Data as seen from OSV
#      when /ERROR.*exists already.*$/
#        returnvalue = 100
#        resulttext = "üüüüüüüüüüüüüüüüüüstopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/Site Name .* exists already.*$|Customer.*exists already.*$/] + '" at ' + Time.now.to_s
#        # TODO: update Site Data as seen from OSV
      when /ERROR.*does not exist.*$/
        returnvalue = 101
        resulttext = "stopped with ERROR[#{returnvalue.to_s}]=\"" + resulttext[/ERROR.*does not exist.*$/][7,400] + '" at ' + Time.now.to_s
      when /Warnings/
        returnvalue = 5
        resulttext = "Import ERROR[#{returnvalue.to_s}]=\"" + responseBody[/OSV.*Success.*$/] unless responseBody[/OSV.*Success.*$/].nil?
      else
        returnvalue = 1
        resulttext = "finished with unknown ERROR[#{returnvalue.to_s}]=BODY[0,400]=\"" + resulttext[0,400] + '" at ' + Time.now.to_s unless resulttext.nil? 
    end  # case resulttext

    p '------------------resulttext------------------'
    p 'resulttext = ' + resulttext
    p 'returnvalue = ' + returnvalue.to_s
    p '------------------resulttext------------------'
       
    update_attributes(:status => resulttext)
    return returnvalue
  end # def deliver
  
  def createdelayedjob  
    begin # provisioning job still running
      Delayed::Job.find(delayedjob)
    rescue # else
      # create a new provisioning job for the provisioning task
      
      #delayedjob = Delayed::Job.enqueue(ProvisioningJob.new(id))
          # For troubleshooting, it is sometomes better to use the two next commands instead of the delayedjob command
          provisioningjob = ProvisioningJob.new(id)
          provisioningjob.perform
      
      # not needed here, sinc hwere, the delayedjob IS the provisioning attribute?
      #@provisioning.update_attributes(:delayedjob => @delayedjob)
      update_attributes(:delayedjob => delayedjob)      
    end
  end # def createdelayedjob
     
  def destroydelayedjob
    begin
      # delete the background job, if it has not automatically been destroyed (e.g. a job is deleted after finish)
      @job = Delayed::Job.find(delayedjob)
      @job.destroy 
    rescue
      # just continue, if the job is deleted already  
    end
  end
  

#  def initialize(attributes=nil)
#    attr_with_defaults = {:status => "not started", :action => "action=Add Customer, customerName=Cust1"} #.merge(attributes)
#    attr_with_defaults = attr_with_defaults.merge(attributes) unless attributes.nil?
#    super(attr_with_defaults)
#  end

  
  belongs_to :customer
  belongs_to :site
  belongs_to :user
  #handle_asynchronously :deliverasynchronously
  validates_with Validate_action
end
