class UpdateDB
  #
  # Is reading information from the target system and is updating the local database accordingly
  #
  def perform(targetobject)
    
    provisioningRequestTimeout = 10
    	#p '#################  targetobject.name  #################'
  
    responseBody = targetobject.provision(:read, false)

    # depending on the result, targetobject.provision can return a Fixnum. We need to convert this to a String
    if responseBody.is_a?(Fixnum)
      case responseBody
        when 101
          responseBody = "ERROR: #{targetobject.class.name} does not exist"
      end
    end

    # abort, if it is still a Fixnum:
    if responseBody.is_a?(Fixnum)
      abort "ERROR: wrong responseBody type (Fixnum (#{responseBody}) instead of String)"
    end
    
    # only Customer, Site, User are supported:
    abort "lib/update_db.rb.perform(targetobject): Unsupported class" unless targetobject.is_a?(Customer) || targetobject.is_a?(Site) || targetobject.is_a?(User)
    
    if responseBody.nil?
      return "ERROR: UpdateDB: provisioningRequest timeout (#{provisioningRequestTimeout} sec) reached!"
    end

      
    unless responseBody[/ERROR.*$/].nil?
      return responseBody[/ERROR.*$/]
    end if responseBody.is_a?(String)
    
    require 'rexml/document'
    xml_data = responseBody
    doc = REXML::Document.new(xml_data)
    
    if targetobject.is_a?(Customer)
	#p xml_data.inspect
	#abort doc.root.elements["GetBGListData"].elements["BGName"].inspect
      found = false
      doc.root.elements["GetBGListData"].elements.each do |element|
        if element.text == targetobject.name
          targetobject.update_attribute('status', 'provisioning successful (verified existence)')
          found = true
          break
        end
      end  
      # not found
      targetobject.update_attribute('status', 'not provisioned (verified)') unless found
    elsif targetobject.is_a?(Site)
      found = false
      doc.root.elements["Sites"].elements.each do |element|
        if element.elements["SiteName"].text == targetobject.name
          found = true
          # Note: update_attributes does a validation, and update_attribute does not. 
	  # We cannot update the extensionlength and mainextension at the same time, since they depend on each other
          targetobject.update_attribute('sitecode', element.elements["SiteCode"].text ) unless element.elements["SiteCode"].nil?
          targetobject.update_attribute('gatewayIP', element.elements["GatewayIP"].text ) unless element.elements["GatewayIP"].nil?
          targetobject.update_attribute('countrycode', element.elements["CountryCode"].text )
          targetobject.update_attribute('areacode', element.elements["AreaCode"].text )
          targetobject.update_attribute('localofficecode', element.elements["LocalOfficeCode"].text )
          targetobject.update_attribute('extensionlength', element.elements["ExtensionLength"].text )
          # MainNumber is either nil (if there is no local gateway) or it is a full E.164 number, while mainextension is only an extension.
          # => we need to calculate the mainextension from the MainNumber to be the last extensionlength digits:
          if !element.elements["MainNumber"].text.nil? && targetobject.extensionlength.to_i < element.elements["MainNumber"].text.length
            targetobject.update_attribute('mainextension', element.elements["MainNumber"].text[-targetobject.extensionlength.to_i..-1] )
          elsif element.elements["MainNumber"].text.nil?
            targetobject.update_attribute('mainextension', nil)
          end
          targetobject.update_attribute('status', 'provisioning successful (synchronized all parameters)')
          break
        end
      end
      # not found
      targetobject.update_attribute('status', 'not provisioned (verified)') unless found
    elsif targetobject.is_a?(User)
	#p xml_data.inspect
	#abort doc.root.inspect
      found = false
      doc.root.elements.each do |element|
        if element.text == "#{targetobject.site.countrycode}#{targetobject.site.areacode}#{targetobject.site.localofficecode}#{targetobject.extension}"
          targetobject.update_attribute('status', 'provisioning successful (verified existence)')
          found = true
          break
        end
      end      
      targetobject.update_attribute('status', 'not provisioned (verified)') unless found
    end

    p 'UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU    lib/update_db.rb.perform: responseBody    UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU'
    p responseBody.inspect
    
    return responseBody[0,400]
  end # def perform
end
