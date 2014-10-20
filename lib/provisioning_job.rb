class ProvisioningRequest
  def perform(action, uriString=ENV["PROVISIONINGENGINE_CAMEL_URL"], httpreadtimeout=4*3600, httpopentimeout=6)
    #httpopentimeout = 5
    #httpreadtimeout = 4*3600 # allow for 4 hours for deletion of large customer bases
    
  
    #update_attributes(:status => 'started at ' + Time.now.to_s)
    
    require "net/http"
    require "uri"
    
    uri = URI.parse(uriString)
    
    #response = Net::HTTP.post_form(uri, {"testMode" => "testMode", "offlineMode" => "offlineMode", "action" => "Add Customer", "customerName" => @customer.name})
    #OV replaced by (since I want to control the timers):
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = httpopentimeout
    http.read_timeout = httpreadtimeout
    request = Net::HTTP::Post.new(uri.request_uri)
    #requestviatyphoeus = Typhoeus::Request.new("http://localhost/CloudWebPortal")
    


    array = action.split(/,/).map(&:strip)
    p '------------------------------'
    p 'action = ' + action.inspect
    p '------------------------------'
    p 'array = ' + array.inspect
    postData = {}

    while array[0]
      arrayElement = array.shift #.split(/=/).map(&:strip)
      p '------------------------------'
      p 'arrayElement = ' + arrayElement.inspect
      variableValuePairArray = arrayElement.split(/=/).map(&:strip)
      p '------------------------------'
      p 'variableValuePairArray = ' + variableValuePairArray.inspect
      if variableValuePairArray.length.to_s[/^2$/]
        postData[variableValuePairArray[0]] = variableValuePairArray[1]
      elsif variableValuePairArray.length.to_s[/^1$/]
        postData[variableValuePairArray[0]] = ""
      else
        abort "action (here: #{action}) must be of the format \"variable1=value1,variable2=value2, ...\""
      end
    end
    
    p '------------------------------'
    p 'postData = ' + postData.inspect
    p '------------------------------'
    
    request.set_form_data(postData)
    
    begin
      response = http.request(request)
      responseBody = response.body
    rescue
      responseBody = nil
    end
    return responseBody
  end
end
  

class UpdateDB
  #
  # Is reading information from the target system and is updating the local database accordingly
  #
  def perform(targetobject)
    p '#################  targetobject.name  #################'
#    targetobjects.each do |targetobject|
      p targetobject.name unless targetobject.nil?
#    end

    provisioningRequest = ProvisioningRequest.new
    responseBody = provisioningRequest.perform("Show Sites, customerName=#{targetobject.customer.name}", ENV["PROVISIONINGENGINE_CAMEL_URL"], 10) unless targetobject.customer.nil?
    
    p 'UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU'
    p responseBody unless responseBody.nil?
  end
end

class ProvisioningJob < Struct.new(:provisioning_id)
  #
  # OV: see http://www.de.asciicasts.com/episodes/171-delayed-job
  # 
    
  def perform
    
    #
    # INIT: update status
    #

    
    provisioning = Provisioning.find(provisioning_id)
    
    if provisioning.nil?
      abort "ProvisioningJob.perform: cannot find provisioning with id=#{provisioning_id}"
    end

    if provisioning.attempts.nil?
      provisioning.update_attributes(:attempts => 1 )
    else
      provisioning.update_attributes(:attempts => provisioning.attempts + 1 )
    end
      
    # map the action of the provisioningEngine to provisioning status
    thisaction = 'provisioning' unless provisioning.action[/Add/].nil?
    thisaction = 'deletion' unless provisioning.action[/Delete/].nil?
    # if not found:
    thisaction = 'unknown action' if thisaction.nil?  
    
    targetobjects = [provisioning.user, provisioning.site, provisioning.customer] # extend, if needed
    
    

    # update the stats uf the target objects
    #   e.g. with "provisioning.action = 'Add Customer, ...', update the status of the customer object to 'provisioning in progress'"
    targetobjects.each do |targetobject|
      targetobject.update_attributes(:status => thisaction + ' in progress') unless targetobject.nil?
    end
    
    
    #
    # Perform Provisioning
    #
    deliverresult = provisioning.deliver
      # error codes:
      # 0 = success
      # 3 = timeout
      # 4 = test mode
      # 5 = import errors
      # 100 = failure: object already created
      # 101 = failure: object already deleted
      # else: unknown failure
    
    #
    # Update status after provisioning attempt
    #
    case deliverresult
      when 0 # success
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
      when 1 # unknown error
        targetobjects.each do |targetobject|
          targetobject.update_attributes(:status => thisaction + ' failed (unknown error); stopped') unless targetobject.nil?
          break unless targetobject.nil?
        end      
      when 3 # timeout
        targetobjects.each do |targetobject|
          targetobject.update_attributes(:status => thisaction + ' failed (timed out); trying again') unless targetobject.nil?
          break unless targetobject.nil?
        end
        abort 'ProvisioningJob.perform: connection timout'
      when 4 # test mode
        targetobjects.each do |targetobject|
          targetobject.update_attributes(:status => thisaction + ' successful (test mode)') unless targetobject.nil?
          break unless targetobject.nil? 
        end
        #provisioning.update_attributes(:delayedjob => nil)
      when 5 # import errors
        targetobjects.each do |targetobject|
          targetobject.update_attributes(:status => thisaction + ' failed (import errors)') unless targetobject.nil?
          break unless targetobject.nil?
        end
        #provisioning.update_attributes(:delayedjob => nil)
      when 6 # deletion script or ccc.sh script aborted
        targetobjects.each do |targetobject|
          targetobject.update_attributes(:status => thisaction + ' failed (script error)') unless targetobject.nil?
          break unless targetobject.nil?
        end
      when 7 # OSV shared library export bug
        targetobjects.each do |targetobject|
          targetobject.update_attributes(:status => thisaction + ' failed (OSV export error)') unless targetobject.nil?
          break unless targetobject.nil?       
        end
        abort 'ProvisioningJob.perform: OSV export error'
      when 100 # failure: object exists already
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
      when 101 # failure: object already deleted
        targetobjects.each do |targetobject|
          targetobject.update_attributes(:status => thisaction + ' failed: was already de-provisioned') unless targetobject.nil?
          # instead of updating the status, remove from database (can be commented out)
          unless targetobject.nil?
            targetobject.destroy
            break
          end 
        end 
      else # failure
        targetobjects.each do |targetobject|
          targetobject.update_attributes(:status => thisaction + ' failed') unless targetobject.nil?
          break unless targetobject.nil? 
        end
    end # case
    
  end # def perform
end
