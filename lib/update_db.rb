class UpdateDB
  #
  # Is reading information from the target system and is updating the local database accordingly
  #
  def perform(targetobject) #, recursive=true)
    
    if targetobject.is_a?(Target)
      # provision
      return false
    else
      responseBody = targetobject.provision(:read, false)
    end

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
    abort "lib/update_db.rb.perform(targetobject): Unsupported class" unless targetobject.is_a?(Customer) || targetobject.is_a?(Site) || targetobject.is_a?(User) || targetobject == Customer || targetobject == Site || targetobject == User
#abort (targetobject == Customer).inspect
    
    if responseBody.nil?
      return "ERROR: UpdateDB: provisioningRequest timeout (#{provisioningRequestTimeout} sec) reached!"
    end

      
    unless responseBody[/ERROR.*$/].nil?
      return responseBody[/ERROR.*$/]
    end if responseBody.is_a?(String)

    require 'rexml/document'
    xml_data = responseBody
    doc = REXML::Document.new(xml_data)
    

    if targetobject.is_a?(Target)
      abort "synchronization of Targets is not supported (yet)"      
    elsif targetobject.is_a?(Customer) || targetobject == Customer
	#p xml_data.inspect
	#abort doc.root.elements["GetBGListData"].elements["BGName"].inspect
		#abort targetobject.inspect
      if targetobject.name.match(/_sync_dummyCustomer_________________/) || targetobject == Customer #targetobject.id.nil? 
        # assume that this is a dummy targetobject that has been created to synchronize all instances from the target system to the DB
        # TODO: create customers that are on the target system and not in the DB
		#abort doc.root.elements["GetBGListData"].elements.inspect
        doc.root.elements["GetBGListData"].elements.each do |element|
		#abort element.text.inspect
          # skip special customer (BG) named BG_DC
          next if /\ABG_DC\Z/.match( element.text )
          # skip if the customer exists already in the database:
		#abort xml_data.inspect
          next if Customer.where(name: element.text).count > 0 
		#abort element.text

          # found an object that is not in the DB:
          newCustomer = Customer.new(name: element.text, target_id: targetobject.target.id)
          # note: update_attribute will save the object, even if the validations fail:
          newCustomer.update_attribute(:status, 'found on target but not yet synchronized')
          UpdateDB.new.perform(newCustomer)
		#abort newCustomer.inspect

          newCustomer.save!(validate: false) 
		#abort Site.where(name: element.elements["SiteName"].text, customer: targetobject.customer).inspect
          # not needed, since it was already updated via UpdateDB.new.perform(newUser):
          #newSite.synchronizeSynchronously(false)

        end
      else
        found = false
        doc.root.elements["GetBGListData"].elements.each do |element|
          if element.text == targetobject.name
            targetobject.update_attribute('status', 'provisioning successful (verified existence)') unless targetobject.id.nil? # do not save an unsaved object here
            found = true
            break
          end
        end  
        # not found
        targetobject.update_attribute('status', 'not provisioned (verified)') unless found
      end
    elsif targetobject.is_a?(Site)
      if targetobject.id.nil? 
        # for verifying manually that the rspec test fails in case this part is not implemented yet:
        #return true

		#abort xml_data.inspect
		#abort targetobject.id.inspect
		#abort doc.root.elements["Sites"].inspect
        # assume that this is a dummy targetobject that has been created to synchronize all instances from the target system to the DB
        # TODO: create provisioningobjects that are on the target system and not in the DB
        doc.root.elements["Sites"].elements.each do |element|
          # skip the common numbering plan (does not correspond to a real site)
          next if /\ACNP_/.match( element.elements["NumberingPlanName"].text )

          # create sites found on the target, if not already in the DB:
          next if Site.where(name: element.elements["SiteName"].text, customer: targetobject.customer).count > 0

          # found an object that is not in the DB:
          newSite = Site.new(name: element.elements["SiteName"].text, customer: targetobject.customer)
          # note: update_attribute will save the object, even if the validations fail:
          newSite.update_attribute(:status, 'found on target but not yet synchronized')
          UpdateDB.new.perform(newSite) 
            
          newSite.save!(validate: false)
		#abort Site.where(name: element.elements["SiteName"].text, customer: targetobject.customer).inspect
          # not needed, since it was already updated via UpdateDB.new.perform(newUser):
          #newSite.synchronizeSynchronously(false)
          
        end # doc.root.elements["Sites"].elements.each do |element|
      else # if targetobject.id.nil?
        found = false
        doc.root.elements["Sites"].elements.each do |element|
          p "UpdateDB: could not find element.elements[\"SiteName\"] in responsebody = #{responseBody}" if element.elements["SiteName"].nil?
          if !element.elements["SiteName"].nil? && element.elements["SiteName"].text == targetobject.name
            found = true
            # Note: update_attributes does a validation, and update_attribute does not. 
	    # We cannot update the extensionlength and mainextension at the same time, since they depend on each other
            {sitecode: "SiteCode", gatewayIP: "GatewayIP", countrycode: "CountryCode", areacode: "AreaCode", localofficecode: "LocalOfficeCode", extensionlength: "ExtensionLength"}.each do |key, value|
              targetobject.update_attribute(key, element.elements[value].text) unless element.elements[value].nil?
            end
#            targetobject.update_attribute('sitecode', element.elements["SiteCode"].text ) unless element.elements["SiteCode"].nil?
#            targetobject.update_attribute('gatewayIP', element.elements["GatewayIP"].text ) unless element.elements["GatewayIP"].nil?
#            targetobject.update_attribute('countrycode', element.elements["CountryCode"].text ) unless element.elements["CountryCode"].nil?
#            targetobject.update_attribute('areacode', element.elements["AreaCode"].text )
#            targetobject.update_attribute('localofficecode', element.elements["LocalOfficeCode"].text )
#            targetobject.update_attribute('extensionlength', element.elements["ExtensionLength"].text )
            # MainNumber is either nil (if there is no local gateway) or it is a full E.164 number, while mainextension is only an extension.
            # => we need to calculate the mainextension from the MainNumber to be the last extensionlength digits:
            if !element.elements["MainNumber"].text.nil? && targetobject.extensionlength.to_i < element.elements["MainNumber"].text.length
              targetobject.update_attribute('mainextension', element.elements["MainNumber"].text[-targetobject.extensionlength.to_i..-1] )
            elsif element.elements["MainNumber"].text.nil?
              targetobject.update_attribute('mainextension', nil)
            end
            targetobject.update_attribute('status', 'provisioning successful (synchronized all parameters)')
            break
          end # if element.elements["SiteName"].text == targetobject.name
        end # doc.root.elements["Sites"].elements.each do |element|
        # not found
        targetobject.update_attribute('status', 'not provisioned (verified)') unless found
      end # if targetobject.id.nil?
    elsif targetobject.is_a?(User)
      if targetobject.id.nil?
        # for verifying manually that the rspec test fails in case this part is not implemented yet:
        #return true

		#abort xml_data.inspect
		#abort targetobject.id.inspect
		#abort doc.root.elements.inspect
        # assume that this is a dummy targetobject that has been created to synchronize all instances from the target system to the DB
        # TODO: create provisioningobjects that are on the target system and not in the DB
        doc.root.elements.each do |element|
		#abort element.text.inspect
          # skip the common numbering plan (does not correspond to a real site)
          next if /\A999999999[0-9]/.match( element.text )
		#abort /\A#{targetobject.site.countrycode}#{targetobject.site.areacode}#{targetobject.site.localofficecode}/.inspect
          next unless /\A#{targetobject.site.countrycode}#{targetobject.site.areacode}#{targetobject.site.localofficecode}/.match( element.text )
          this_extension = element.text.gsub(/\A#{targetobject.site.countrycode}#{targetobject.site.areacode}#{targetobject.site.localofficecode}(.*\Z)/,'\1')
		#abort this_extension

          # if we reach here, all parameters from countrycode to localofficecode match the site data. Now, we check, if the extension is already known:
          next if User.where(extension: this_extension, site: targetobject.site).count > 0
          # create user, if if does not exist already in the DB:
          newUser = User.new(name: this_extension, extension: this_extension,  site: targetobject.site) 
          # note: update_attribute will save the site, ven if the validations fail:
          newUser.update_attribute(:status, 'found on target but not yet synchronized')
		#abort User.where(extension: this_extension,  site: targetobject.site).inspect
          UpdateDB.new.perform(newUser)

          newUser.save!(validate: false)
		#abort User.where(extension: this_extension,  site: targetobject.site).inspect
          # not needed, since it was already updated via UpdateDB.new.perform(newUser):
          #newUser.synchronizeSynchronously(false)
          
        end # doc.root.elements["Sites"].elements.each do |element|
      else # if targetobject.id.nil?
	#p xml_data.inspect
	#abort doc.root.inspect
        found = false
        doc.root.elements.each do |element|
          if element.text == "#{targetobject.site.countrycode}#{targetobject.site.areacode}#{targetobject.site.localofficecode}#{targetobject.extension}"
            targetobject.update_attribute('status', 'provisioning successful (verified existence)') unless targetobject.id.nil? # do not save an unsaved object here
            found = true
            break
          end
        end      
        targetobject.update_attribute('status', 'not provisioned (verified)') unless found
      end # if targetobject.id.nil?
    end

    p 'UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU    lib/update_db.rb.perform: responseBody    UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU'
    p responseBody.inspect
    
    return responseBody[0,400]
  end # def perform
end
