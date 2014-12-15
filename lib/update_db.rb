class UpdateDB
  #
  # Is reading information from the target system and is updating the local database accordingly
  #
  def perform(targetobject)
    
    provisioningRequestTimeout = 10
    p '#################  targetobject.name  #################'
#    targetobjects.each do |targetobject|
      p targetobject.name unless targetobject.nil?
#    end

    # perform is only supported for targetobject of type Site (as of today)
    if !targetobject.is_a?(Site)
      return 1
    end
      
    provisioningRequest = HttpPostRequest.new
    
    if targetobject.is_a?(Site)
      responseBody = provisioningRequest.perform("customerName=#{targetobject.customer.name}, action = Show Sites, SiteName=#{targetobject.name}", ENV["PROVISIONINGENGINE_CAMEL_URL"], provisioningRequestTimeout) unless targetobject.customer.nil?
    elsif targetobject.is_a?(Customer)
      # today, customers have no parameters, which need to be synchronized
      responseBody = "Synchronization not supported for class Customer"
      return 0
    elsif targetobject.is_a?(User)
      responseBody = "Synchronization not supported for class User"
      # today, users are not supported, since the Apache Camel ProvisioningEngine does not support "Show Users" (only "List Users")
      return 1
      #responseBody = provisioningRequest.perform("action = Show Users, customerName=#{targetobject.customer.name}, SiteName=#{targetobject.name}", X=#{targetobject.extension}", "http://localhost/CloudWebPortal", 10) unless targetobject.customer.nil?
    else
      # unsupported class
      return 1
    end
    
    if responseBody.nil?
      return "ERROR: UpdateDB: provisioningRequest timeout (#{provisioningRequestTimeout} sec) reached!"
    end
      
    unless responseBody[/ERROR.*$/].nil?
      return responseBody[/ERROR.*$/]
    end
    
    require 'rexml/document'
    xml_data = responseBody
    doc = REXML::Document.new(xml_data)
    
    if targetobject.is_a?(Site)
      doc.root.elements["Sites"].elements.each do |element|
        if element.elements["SiteName"].text == targetobject.name
          # Note: update_attributes does a validation, and update_attribute does not. We cannot update the extensionlength and mainextension at the same time, since they depend on each other
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
          break
        end
      end
    elsif targetobject.is_a?(User)
      doc.root.elements["Users"].elements.each do |element|
        if element.elements["UserName"].text == targetobject.name
          # Note: update_attributes does a validation, and update_attribute does not. We cannot update the extensionlength and mainextension at the same time, since they depend on each other
          targetobject.update_attribute('givenname', element.elements["GivenName"].text )
          targetobject.update_attribute('familyname', element.elements["FamilyName"].text )
          targetobject.update_attribute('email', element.elements["Email"].text )
          break
        end
      end      
    end

    p 'UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU    responseBody    UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU'
    p responseBody unless responseBody.nil?
    
    return responseBody[0,400]
  end # def perform
end
