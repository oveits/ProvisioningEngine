require 'spec_helper'
require 'rspec/its'

RSpec.configure do |config|
  # see http://stackoverflow.com/questions/9475857/rspec-and-named-routes
  config.include Rails.application.routes.url_helpers
  
  # OV: to get rid of a deprecation warning "Using `should` from rspec-expectations' old `:should` syntax without explicitly enabling the syntax is deprecated."
  #     and allow for "should" directives in rspec (better use expect ... in future)
  #config.expect_with(:rspec) { |c| c.syntax = :should }
  # commented out, because it cannot be set without replacing all 'expect' directives to 'should' directives. This does not make sense. 
  # Better accept the deprecation warning for now and replace 'should' with 'expect' later, if needed
  
  # run all test cases, but not the broken ones:
  myFilter = {broken: true}
  if SystemSetting.webportal_simulation_mode
    myFilter[:simulationbroken] =  true
  end
  
  unless SystemSetting.webportal_async_mode
    myFilter[:syncmodebroken] =  true
  end
  
  myFilter[:obsolete] = true
  
  config.filter_run_excluding(myFilter)
  
  # stop on first failure, if set to true:
#  config.fail_fast = false
  config.fail_fast = true

  # TODO: this filter does not work: run only broken test cases
  #config.filter_run_excluding broken: false #, provisioning: true #, untested: true
end

def expectedProvisionStatus
  case SystemSetting.webportal_async_mode
  when true
    "waiting for provisioning"
  else
    "is provisioned"
  end
end

def expectedProvisionFlash
  case SystemSetting.webportal_async_mode
  when true
    "is being created|is being provisioned"
  else
    "is provisioned"
  end
end

def expectedDeprovisionStatus
  case SystemSetting.webportal_async_mode
  when true
    "waiting for de-provisioning"
  else
    "is de-provisioned"
  end
end

# if set to false, the Gatewayip input is kept empty, when a new site is created
#$setgatewayip = false
$setgatewayip = true
#TODO: replace with
#      setgatewayipList = Array[nil, "47.68.190.57"]
#      and iterate over the list

$FPAFOmitBool = true
if $FPAFOmitBool
  $FPAFOmit = ",FPAFOmit=true"
else
  $FPAFOmit = ""
end

#TODO: add iteration over versions
#      versionList = Array["V7R1", "V8"]
#      and iterate over versionList, and set targetsolution

objectList = Array["Customer", "Site", "User"]
#objectList = Array["Customer", "User"]
#objectList = Array["Customer"]
#objectList = Array["Site"]
#objectList = Array["User"]

objectList2 = Array["Provisioning", "Target"]

# init: we aqlways want to start with an empty SystemSetting database 
# (causing the systemsettings to be controlled by config/application.*):
SystemSetting.all.each do |system_setting|
  system_setting.destroy!
end

if SystemSetting.webportal_simulation_mode
  
  targetsolutionList = Array["Environment1_V8", "Environment2_V7R1"]
#  targetsolutionList = Array["Environment1"]
#  targetsolutionList = Array["Environment2_V7R1"]
  
else
   
#targetsolutionList = Array["CSL6_V7R1", "CSL8", "CSL9_V7R1", "CSL9DEV", "CSL11", "CSL12"]
targetsolutionList = Array["CSL8", "CSL9_V7R1"]
#targetsolutionList = Array["CSL6_V7R1"]  # OSV V7R1, Erik Luft
#targetsolutionList = Array["CSL8"]  # OSV V8R0, Thomas Otto
#targetsolutionList = Array["CSL9_V7R1"]  # OSV V7R1, Pascal Welz
targetsolutionList = Array["CSL9DEV"]  # OSV V8R0, Thomas Otto
#targetsolutionList = Array["CSL11"]   # OSV V8R0, Rolf Lang
#targetsolutionList = Array["CSL12"]  # AcmePacket; Joerg Seifert
 
end # if SystemSetting.webportal_simulation_mode


def parent(obj)
  case obj
    when /Target/
      nil
    when /Customer/
      "Target"
    when /Site/
      "Customer"
    when /User/
      "Site"
  end
end

def child(obj)
  case obj
    when /Target/
      "Customer"
    when /Customer/
      "Site"
    when /Site/
      "User"
    when /User/
      nil
  end
end

#def myObject(obj) #(obj="Customer")
def myObject(obj="Customer")
  #"Customer"
  obj
end

def myObjects(obj=myObject)
  # Customers
  "#{myObject(obj).pluralize}"
end

def myobject(obj=myObject)
  # customer
  myObject(obj).downcase
end

def myobjects(obj=myObject)
  # customers
  myObjects(obj).downcase
end

def provisioningobject_path(thisobject, prefix=nil)
  # returns e.g. customer_path
  prefixPrepend = "#{prefix}_" unless prefix.nil?
  path = send("#{prefixPrepend}#{myobject(thisobject.class.to_s)}_path", thisobject.id)
end

def myProvisioningobject(obj)
  Object.const_get(myObject(obj))
end

def provisioningobjects_path(obj)
  # return the path to the obj index as String, e.g. customers_path = (/dev) "/customers/" or "/dev/customers" in case WEBPORTAL_BASEURL = '/dev'
 		#abort send("#{myobjects(obj)}_path".to_sym) + "?per_page=0"

  # index page with no pagination, so all entries can be seen:
  send("#{myobjects(obj)}_path".to_sym) + "?per_page=all"
end

def new_provisioningobject_path(obj)
  #new_customer_path
  send("new_#{myobject(obj)}_path".to_sym)
end

def synchronize_provisioningobjects_path(obj)
  #new_customer_path
  send("synchronize_#{myobjects(obj)}_path".to_sym)
end


#def createCustomer(name = "" )      
#  # add and provision customer "ExampleCustomerV8 with target = TestTarget" 
#  obj = "Customer"
#  
#  fillFormForNewCustomer(name)
##abort "createCustomer: abort"
#  click_button 'Save', match: :first 
#end

def defaultParams(obj, i = 0)
  #paramsSet = []
  case obj
    when /Target/
      case i
        when 0
          paramsSet = {
              name: $targetname,
              configuration: $target
              }
      end     
    when /Customer/
      case i
        when 0
          paramsSet = {
              name: "ExampleCustomerV8",
              language: "german",
              }
        when 2
          paramsSet = {
              name: "Customer2",
              language: "german",
              }
        when 3
          paramsSet = {
              name: "Customer3",
              language: "german",
              }
      end
    when /Site/
      case i
        when 0
          paramsSet = {
              name: "ExampleSite",
              countrycode: "49",
              areacode: "99",
              localofficecode: "7007",
              extensionlength: "5",
              mainextension: "10000",
    	        gatewayIP: "47.68.190.57"
              }
          if /V7R1/.match($targetname)
            paramsSet[:sitecode] = "99821"
          end
        when 1
          paramsSet = {
              # must have the same name as paramsSet 0, since it is used 
	      # to change all attributes but name in the DB, and check that 
              # the attributes are correct again after a sync with the target
              name: "ExampleSite",
              countrycode: "1",
              areacode: "2",
              localofficecode: "3",
              extensionlength: "4",
              mainextension: "5555",
              gatewayIP: "2.56.23.45"
              }
          if /V7R1/.match($targetname)
            paramsSet[:sitecode] = "442211"
          end
        when 2
          paramsSet = {
              name: "Site2",
              countrycode: "1",
              areacode: "22",
              localofficecode: "333",
              extensionlength: "4",
              mainextension: "5555",
              gatewayIP: "85.2.56.2"
              }
          if /V7R1/.match($targetname)
            paramsSet[:sitecode] = "112233"
          end
       when 3
          paramsSet = {
              name: "Site3",
              countrycode: "44",
              areacode: "66",
              localofficecode: "777",
              extensionlength: "3",
              mainextension: "222",
              gatewayIP: "93.56.96.12"
              }
           if /V7R1/.match($targetname)
            paramsSet[:sitecode] = "446677"
	    #  for this version, only CC=49 is supported:
	    paramsSet[:countrycode] = "49"
          end
      end
      
    when /User/
      case i
        when 0
          paramsSet= {
              name: "ExampleUser",
              extension: "30800",
              givenname: "Oliver",
              familyname: "Veits",
              email: "oliver.veits@company.com"
              }
        when 2
          paramsSet= {
              name: "ExampleUser2",
              extension: "47111",
              givenname: "User2",
              familyname: "TestUser2",
              email: "user2.testuser2@company.com"
              }
        when 3
          paramsSet= {
              name: "ExampleUser3",
              extension: "47113",
              givenname: "User3",
              familyname: "TestUser3",
              email: "user3.testuser3@company.com"
              }
      end
    else
      abort "obj=#{obj} not supported for function defaultParams(obj)"
  end
  #abort "Could not find defaultParams for i=#{i}" if paramsSet.nil?
  paramsSet
end

def initObj(paramsHash)
  # e.g.:
  # initObj(obj: "Customer", shall_exist_on_db: true, shall_exist_on_target: true, defaultParams("Customer", 0))
#abort paramsHash.inspect unless paramsHash[:paramsSet].nil?
  return false unless paramsHash.is_a?(Hash)

  # init
  obj = paramsHash[:obj]
  shall_exist_on_db = paramsHash[:shall_exist_on_db]
  shall_exist_on_target = paramsHash[:shall_exist_on_target]
  paramsSet = paramsHash[:paramsSet]
      #abort paramsSet.inspect unless paramsHash[:paramsSet].nil?

  # validation
  return false if obj.nil?
  
  # default values:
  shall_exist_on_db = true if shall_exist_on_db.nil?
  shall_exist_on_target = true if shall_exist_on_target.nil?
  paramsSet = defaultParams(obj, 0) if paramsSet.nil?

      #abort paramsSet.inspect unless paramsHash[:paramsSet].nil?
  
  myObj = createObjDB(obj, paramsSet)
  
        #abort myObj.inspect unless paramsHash[:paramsSet].nil?

  # probe whether obj exists on target
  # -> set exists_on_target accordingly

  if shall_exist_on_target
    # provision
    myObj.provision(:create, false) unless myObj.class.name == "Target" # since not supported yet on Target
  else
    # recursive deprovisioning of children only for paramsSet 0:
    if paramsSet == defaultParams(obj, 0)
      initObj(obj: child(obj), shall_exist_on_db: true, shall_exist_on_target: false) unless child(obj).nil?
    end
    myObj.provision(:destroy, false)    
  end

  if shall_exist_on_db == false
    # destroy! 
    myObj.destroy!
          #abort myObj.inspect
  else
    return myObj
  end
end

def createObjDB(obj, paramsSet = nil) 
  # creates an object and its parent object (recursively) in the database, if it does not exist
  # returns the existing object, if it exists

  # set default paramsSet:
  if paramsSet.is_a?(Fixnum)
    # this will change paramsSet from Fixnum to Hash:
    paramsSet = defaultParams(obj, paramsSet)
  end

  if  paramsSet.nil? 
    paramsSet = defaultParams(obj, 0) 
  end

  if obj.constantize.where(paramsSet).count == 0 
    # create parent, if it does not exist and add the parent id to the paramsSet:
    # clone paramsSet, since we do now want to change input parameters
    paramsSetWithParent = paramsSet.clone
    paramsSetWithParent = paramsSetWithParent.merge!("#{parent(obj).downcase}_id".to_sym => createObjDB(parent(obj)).id) unless parent(obj).nil?
    # create the object:
    myObj = obj.constantize.new(
      paramsSetWithParent
    )
          #abort paramsSetWithParent.inspect
    myObj.save!
  end

  if obj.constantize.where(paramsSetWithParent).count == 1
    myObj = obj.constantize.where(paramsSetWithParent).last
  else
    abort "More than one #{obj} found matching the parameters=#{paramsSetWithParent.inspect}"
  end

  return myObj
end # def createObjDB(obj, paramsSet = nil)

def sync(syncObj, async=false)
	#abort "sync(#{syncObj.inspect})"
#  updateDB = UpdateDB.new
#  returnBody = updateDB.perform(syncObj)
  syncObj.synchronize(async)
	#abort returnBody
end

def createSite(name = "ExampleSite" )      
  # add and provision customer "ExampleCustomerV8 with target = TestTarget" 
  fillFormForNewSite(name)
  click_button 'Save', match: :first 
end

def createCustomer(name = $customerName )      
  # add and provision customer "ExampleCustomerV8 with target = TestTarget" 
  fillFormForNewCustomer(name)
  click_button 'Save', match: :first 
end

def createObject(obj, name = "" )        
  fillFormForNewObject(obj, name)
    
  click_button 'Save', match: :first 
  	#p page.html.gsub(/[\n\t]/, '').inspect if obj == "Site"
  if /V7R1/.match($targetname) && page.html.gsub(/[\n\t]/, '').match("Sitecode must not be empty for V7R1 targets") 
    fill_in "Sitecode",         with: "99821"
    click_button 'Save', match: :first
  end
	#p page.html.gsub(/[\n\t]/, '').inspect if obj == "User"

  # return value: url or nil
  if /http.*\/#{myobjects(obj)}\/[1-9][0-9]*\Z/.match(page.current_url).nil?
    #returnval = 
    nil
  else
    #returnval = 
    page.current_url
  end
#abort returnval.inspect
end

def deleteObjectURLfromDB(obj, myURL)
# TODO: should retunt "http://www.example.com/sites/1" but returns "http://www.example.com/sites" only...
  visit myURL
  if myURL == page.current_url
    # find object in DB and delete it
    obj_id = /[1-9][0-9]*\Z/.match(page.current_url).to_s.to_i
    myProvisioningobject(obj).find(obj_id).destroy!
  else
    abort "Cannot find URL #{myURL}"
  end
end

def createCustomerDB(customerName = "nonProvisionedCust" )
  obj = "Customer"
	# creates a customer in the database without provisioning job

	# I have problems with FactoryGirls for adding database entries.
        # workaround: create customer by /customer/new click 'save' and remove the delayed job that is created 
        # the following works only, if delayed jobs is shut down, i.e. "rake jobs:work" is not allowed
        Delayed::Worker.delay_jobs = true
        createCustomer(customerName)

        # delete all delayed jobs of this customer
        @customer = myProvisioningobject(obj).where(name: customerName )
        @provisionings = Provisioning.where(customer: @customer)
        
        @provisionings.each do |provisioning|
          unless provisioning.delayedjob_id.nil?
            begin
              Delayed::Job.find(provisioning.delayedjob_id).destroy
            rescue
              # do nothing
            end
          end
        end

end #def createCustomerDB(customerName = "nonProvisionedCust" )

def createCustomerDB_not_working
  	FactoryGirl.create(:target)
        delta = myProvisioningobject(obj).count
p myProvisioningobject(obj).count.to_s + "<<<<<<<<<<<<<<<<<<<<< Customer.count before FactoryGirl.create"
        FactoryGirl.create(:customer)
p myProvisioningobject(obj).count.to_s + "<<<<<<<<<<<<<<<<<<<<< Customer.count after FactoryGirl.create"
	customer = myProvisioningobject(obj).find(1)
p customer.name + "<<<<<<<<<<<<<<<< customer.name"
        delta = myProvisioningobject(obj).count - delta
p delta.to_s + "<<<<<<<<<<<<<<<<<<<<< delta(Customer.count)"

end

def createObjectDB_manual(obj)
  case obj
    when /Customer/
      createCustomerDB_manual
    when /Provisioning/
      createProvisioningDB_manual
    when /Target/
      createTargetDB_manual
    else
      abort "Object=#{obj} not supported for function createObjectDB_manual"
  end
end

def createCustomerDB_manual( arguments = {} )
  obj = "Customer"
	# default values
	arguments[:name] ||= "nonProvisionedCust"

        target = Target.new(name: $targetname, configuration: $target)
	target.save
	#customer = myProvisioningobject(obj).new(name: "nonProvisionedCust", target_id: target.id)
	customer = myProvisioningobject(obj).new(name: "nonProvisionedCust", target_id: target.id, language: Customer::LANGUAGE_GERMAN)
        customer.save!
end

def createProvisioningDB_manual( arguments = {} )
  obj = "Provisioning"
	# default values
	arguments[:action] ||= "a=b"

	#customer = myProvisioningobject(obj).new(name: "nonProvisionedCust", target_id: target.id)
	provisioning = Provisioning.new(action: arguments[:action])
        provisioning.save!
end

def createTargetDB_manual( arguments = {} )
  obj = "Target"
        # default values
        arguments[:name] ||= "_Empty_Target"
        #arguments[:configuration] ||= "a=b"

        #customer = myProvisioningobject(obj).new(name: "nonProvisionedCust", target_id: target.id)
        target = Target.new(arguments)
        target.save!
end

def fillFormForNewObject(obj, name="")
  name = $customerName if name == "" && obj == "Customer"
  name = "Example#{obj}" if name == "" && obj != "Customer"
  case obj
    when /Customer/
      fillFormForNewCustomer(name)
    when /Site/
      fillFormForNewSite(name)
    when /User/
      fillFormForNewUser(name)
  end  
end

def fillFormForNewCustomer(name = $customerName )

  if Target.where(name: $targetname).count == 0
    Target.create(name: $targetname, configuration: $target)
  end
  visit new_provisioningobject_path("Customer") # for refreshing after creating the target
  fill_in "Name",         with: name        
  select $targetname, :from => "customer[target_id]"
  select "german", :from => "customer[language]"
  
  # Note: select $targetname selects the <option value=_whatever_>TestTarget</option> in the following select part of the HTML page:
  # Expected drop down in HTML page:
          #    <select id="customer_target_id" name="customer[target_id]">
          #    <option value="">Select a Target</option>
          #    <option value="2">TestTarget</option></select>
end

def fillFormForNewSite(name = "" )
  name = "ExampleSite" if name == ""
  if Customer.where(name: $customerName).count == 0
    delayed_worker_delay_jobs_before = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = false
    createCustomer
    Delayed::Worker.delay_jobs = delayed_worker_delay_jobs_before
  end
  visit new_provisioningobject_path("Site") # for refreshing after creating the target
#p page.html.gsub(/[\n\t]/, '')
  fill_in "Name",         with: name        
  select $customerName, :from => "site[customer_id]"
  #fill_in "Sitecode",         with: "99821" if /V7R1/.match($customerName) # not here, since Sitecode is not visible
  select "49", :from => "site[countrycode]"
  fill_in "Areacode",         with: "99" 
  fill_in "Localofficecode",         with: "7007" 
  fill_in "Extensionlength",         with: "5" 
  fill_in "Mainextension",         with: "10000" 
  fill_in "Gatewayip",         with: "47.68.190.57" unless $setgatewayip == false
  
  # Note: select $targetname selects the <option value=_whatever_>TestTarget</option> in the following select part of the HTML page:
  # Expected drop down in HTML page:
          #    <select id="site_customer_id" name="site[customer_id]"><option value="">Select a Customer</option>
          #    <option value="18">Cust1</option>
          #    <option value="21">Cust2</option></select>
end

def fillFormForNewUser(name = "" )
  name = "ExampleUser" if name == ""
  if Customer.where(name: $customerName).count == 0
    delayed_worker_delay_jobs_before = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = false
    createCustomer
    Delayed::Worker.delay_jobs = delayed_worker_delay_jobs_before
  end
  if Site.where(name: 'ExampleSite').count == 0
    delayed_worker_delay_jobs_before = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = false
    createObject("Site", name = "ExampleSite" ) 
#abort Site.all.inspect
    Delayed::Worker.delay_jobs = delayed_worker_delay_jobs_before
  end
#abort Site.all.inspect
  visit new_provisioningobject_path("User") # for refreshing after creating the target
  #fill_in "Name",         with: name        # not possible, since name input field might not be displayed (depending on the application.yaml file content)
  select "ExampleSite", :from => "user[site_id]"
  fill_in "Extension",         with: "30800"
  fill_in "Givenname",         with: "Oliver" 
  fill_in "Familyname",         with: "Veits" 
  fill_in "Email",         with: "oliver.veits@company.com" 
  
  # Note: select $targetname selects the <option value=_whatever_>TestTarget</option> in the following select part of the HTML page:
  # Expected drop down in HTML page:
          #    <select id="site_customer_id" name="site[customer_id]"><option value="">Select a Customer</option>
          #    <option value="18">Cust1</option>
          #    <option value="21">Cust2</option></select>
end

def destroyCustomer(customerName = $customerName )
  obj = "Customer"
  # for test: create the customer, if it does not exist:
  Delayed::Worker.delay_jobs = true
  createCustomer
  
  # de-provision the customer, if it exists on the target system
  # else delete the customer from the database
  customers = myProvisioningobject(obj).where(name: customerName)
  #p @customers[0].inspect
  unless customers[0].nil?
    Delayed::Worker.delay_jobs = false
    visit provisioningobject_path(customers[0])
    click_link "Destroy", match: :first
    Delayed::Worker.delay_jobs = true
  end
  
  # delete the customer from the database if it still exists
  customers = myProvisioningobject(obj).where(name: customerName)
  unless customers[0].nil?
    Delayed::Worker.delay_jobs = false
    visit provisioningobject_path(customers[0])
    click_link "Destroy", match: :first
    Delayed::Worker.delay_jobs = true
  end
end

def destroyObjectByNameRecursive(obj)
#p "destroyObjectByNameRecursive begin: \n#{page.html.gsub(/[\n\t]/, '')}"
  destroyObjectByName(obj)
  if /script error/.match(page.html.gsub(/[\n\t]/, ''))
    childObj = "Site" if obj == "Customer"
    childObj = "User" if obj == "Site"
    createObject(childObj)
    destroyObjectByName(childObj)
    destroyObjectByName(obj)
  end
#p "destroyObjectByNameRecursive end: \n#{page.html.gsub(/[\n\t]/, '')}"
end

def destroyObjectByName(obj, name = "")
#p "destroyObjectByName begin: \n#{page.html.gsub(/[\n\t]/, '')}"
  # default name:
  name = $customerName if name == "" && obj == "Customer"
  name = "Example#{obj}" if name == "" && obj != "Customer"
  # for test: create the customer, if it does not exist:
  delayedJobsBefore = Delayed::Worker.delay_jobs
  Delayed::Worker.delay_jobs = true

  # TODO: not yet supported:
  #createCustomer / destroyObject(obj)
  
  # de-provision the customer, if it exists on the target system
  # else delete the customer from the database
  myObjects = myProvisioningobject(obj).where(name: name) unless obj == "User"
  myObjects = myProvisioningobject(obj).where(extension: "30800") if obj == "User"  # not sufficient: need to specify the site as well.
  #myObjects = myProvisioningobject(obj).where(name: name) if obj == "User"  # not possible, since name input field might not be displayed (depending on the application.yaml file content)
  #p @customers[0].inspect
  #p myObjects.inspect
  
  # TODO: prio 2 Ticket:
  #       for Sites and Users, more than one object with the same name is allowed, 
  #       1) the current procedure will delete only one of them. Is this the desired 
  #       2) more importantly: it might delete the wrong item, e.g. you want to delete Cust3/Site1, but you might delete Cust1/Site1 instead...
  #       Better not to delete by name at all? Or only, if one, but only one item has this name? Still, a Site is determined by Customer name 
  #       and Site name only. So, if we delete a Site by name, it is better to specify the Customer name as well.
  # Best: test deletions by creating the object, memorize the object id and delete by id instead of by name...
  #       test creations like follows: initialize by checking no duplicate name etc. is on the system. If there is a duplicate name etc on the system, choose another name etc for the creation test.
  #
  # Workaround: make sure the names are unique...
  #
#abort myObjects.inspect
#p myObjects.count.to_s + "<-------------------------------------------------------- myObjects.count.to_s"
#p obj.to_s + "<-------------------------------------------------------- obj.to_s"
#p name.to_s + "<-------------------------------------------------------- name.to_s"

  if myObjects.count == 1
  #unless myObjects[0].nil?
    Delayed::Worker.delay_jobs = false
    visit provisioningobject_path(myObjects[0])
#p page.html.gsub(/[\n\t]/, '')
    #click_link "Destroy", match: :first
    click_link "Delete #{obj}", match: :first
    Delayed::Worker.delay_jobs = delayedJobsBefore
  elsif myObjects.count > 1
    abort "destroyObjectByName(#{obj}, #{name}): found more than one #{obj} with name=#{name}. Aborting..."
  end
  
  # delete the customer from the database if it still exists
  myObjects = myProvisioningobject(obj).where(name: name)
  myObjects = myProvisioningobject(obj).where(extension: "30800") if obj == "User"  # works only, if no other user with extension=30800 is created in the test database
  #myObjects = myProvisioningobject(obj).where(name: name) if obj == "User"  # not possible, since name input field might not be displayed (depending on the application.yaml file content)
  #unless myObjects[0].nil?
  if myObjects.count == 1
    Delayed::Worker.delay_jobs = false
    visit provisioningobject_path(myObjects[0])
    #click_link "Destroy", match: :first
    click_link "Delete #{obj}", match: :first
    Delayed::Worker.delay_jobs = delayedJobsBefore
  elsif myObjects.count > 1
    abort "destroyObjectByName(#{obj}, #{name}): found more than one #{obj} with name=#{name}. Aborting..."
  end  
  Delayed::Worker.delay_jobs = delayedJobsBefore
#p "destroyObjectByName end: \n#{page.html.gsub(/[\n\t]/, '')}"
end

  
  
# shared example:
shared_examples_for Customer do
  #describe "aaa" do
    before { visit customers_path }
    subject { page }
    
    it "should have the header 'Customers'" do
      expect(page).to have_selector('h1', text: Customer.to_s + "s")
    end
  #end
end


targetsolutionList.each do |targetsolution|
  describe "On target solution '#{targetsolution}'" do  
    before do
            #abort targetsolutionList.inspect
      FactoryGirl.create("target_#{targetsolution}".to_sym)
      myTarget = Target.last
      $customerName = "ExampleCustomerV8" #targetsolutionVars[targetsolution][:customerName]
      $targetname = Target.last.name #targetsolutionVars[targetsolution][:targetname]
      $target = Target.last.configuration + $FPAFOmit #targetsolutionVars[targetsolution][:target]
      Target.last.destroy!
    end

    describe "createObjDB('Target')" do
      before do
        # remove all targets:
        Target.all.each do |target|
          target.destroy!
        end
      end # before
  
      it "should dump the target to a seed file" do
        # init:
        myTarget = nil

        # test: creation of new target:
        # add a target:
        expect{ myTarget = createObjDB("Target") }.to change(Object.const_get("Target"), :count)
        expect( myTarget ).to be_a(Target)
        
        SeedDump.dump(Target, file: 'db/seeds_targets.rb', append: true)
        
      end

      it "should create a Target, if it does not exist already" do
        # init:
        myTarget = nil

        # test: creation of new target:
        # add a target:
        expect{ myTarget = createObjDB("Target") }.to change(Object.const_get("Target"), :count)
        expect( myTarget ).to be_a(Target)
      end # it "should create a Target, if it does not exist already" do

      it "should return the existing Target, if it exists already" do
        # init:
        # creation of new target if it does not exist already:
        createObjDB("Target")
        myTarget = nil

        # test: since the target exists alreads, createObjDB should not add a target, but return the existing target:
        expect{ myTarget = createObjDB("Target") }.not_to change(Object.const_get("Target"), :count)
        expect( myTarget ).to be_a(Target)
      end #it "should return the existing Target, if it exists already" do
    end # describe "createObjDB('Target')" do
objectList.each do |obj|
    describe "createObjDB(#{obj})" do
      before do
        # remove all objects:
        Object.const_get(obj).all.each do |myobj|
          myobj.destroy!
        end
        # remove the parent objects, if applicable:
        Object.const_get(parent(obj)).all.each do |myobj|
          myobj.destroy!
        end unless parent(obj).nil?
      end # before do

      it "should create a #{obj}, if it does not exist already" do
        # init:
        myobj = nil
        expect( Object.const_get(parent(obj)).count ).to be(0) unless parent(obj).nil? # no parent object

        # test: creation of new #{obj}:
        # add a #{obj}:
        expect{ myobj = createObjDB(obj) }.to change(Object.const_get(obj), :count)
        # this should have added the parent object:
        expect( Object.const_get(parent(obj)).count ).to be(1) unless parent(obj).nil? # one parent object
        # and the created opbject must be of the right type:
        expect( myobj ).to be_a(Object.const_get(obj))
      end # it "should create a #{obj}, if it does not exist already" do

      it "should return the existing #{obj}, if it exists already" do
        # init:
        # make sure the object exists already:
        createObjDB(obj)
        expect( Object.const_get(parent(obj)).count ).to be(1) unless parent(obj).nil? # one parent object
        myobj = nil
        

        # test: since the #{obj} exists alreads, createObjDB should not add a #{obj}, but return the existing #{obj}:
        expect{ myobj = createObjDB(obj) }.not_to change(Object.const_get(obj), :count)
        expect( Object.const_get(parent(obj)).count ).to be(1) unless parent(obj).nil? # still one parent object
        expect( myobj ).to be_a(Object.const_get(obj))
      end # it "should return the existing #{obj}, if it exists already" do
    end # describe "createObjDB(#{obj})" do  

    describe "initObj(#{obj}) via model" do
      it "initObj( obj: #{obj}, shall_exist_on_db: true, shall_exist_on_target: false ) should create the object with the right attributes in the database and de-provision the object, if it was provisioned" do
  
        # make sure the database does not contain any object of the type obj
        obj.constantize.all.each do |myobject|
          myobject.destroy!
        end
	#@@siteprovisioned = nil

        # make sure the provisioningobject is created on the target (so, we can test, whether init is de-provision the provisioningobject)
        expect{ @myobj = createObjDB(obj) }.to change(Object.const_get(obj), :count).by(1)
        # create children:
        expect{ @mychildobj = createObjDB(child(obj)) }.to change(Object.const_get(child(obj)), :count).by(1) unless child(obj).nil?
#abort child(obj).inspect
#abort createObjDB(child(obj),3).inspect

        # Create "Site3" in the database and deprovision it: 
        # i.e. workaround for non-existent synchronization before recursive deletion within the rspec above
        expect{ @mychildobj2 = createObjDB(child(obj), 3) }.to change(Object.const_get(child(obj)), :count).by(1) unless child(obj).nil? if obj=="Customer"
        # workaround part 2: de-provision Site3 
        @mychildobj2.provision(:create, false) unless child(obj).nil? if obj=="Customer"
        @mychildobj2.provision(:destroy, false) unless child(obj).nil? if obj=="Customer"

        # de-provision the object recursively?
        @myobj.provision(:destroy, false)
#abort Site.all.inspect
        @myobj.provision(:create, false)
        
        # provision children:
        @mychildobj.provision(:create, false) unless child(obj).nil?
        #@mychildobj2.provision(:create, false) unless child(obj).nil? if obj=="Customer"
#abort Site.all.inspect
        expect( @myobj.provision(:read, false) ).to match(/>#{@myobj.name}</) unless obj == "User"
        expect( @myobj.provision(:read, false) ).to match(/>#{@myobj.site.countrycode}#{@myobj.site.areacode}#{@myobj.site.localofficecode}#{@myobj.extension}</) if obj == "User"
        @myobj.destroy!
        
        # test: should create an object
		#p "expect{ initObj(obj: obj, shall_exist_on_db: true, shall_exist_on_target: false) }.to change(Object.const_get(obj), :count).by(1)"
        #expect{ initObj( obj, true, false ) }.to change(Object.const_get(obj), :count).by(1)
        expect{ initObj(obj: obj, shall_exist_on_db: true, shall_exist_on_target: false) }.to change(Object.const_get(obj), :count).by(1)
        
        # test: should have created an object with the right attributes:
        @myobj = Object.const_get(obj).last
        defaultParams(obj).each do |key, value|
          	#p "#{key} => #{value}"
          expect( @myobj.send(key) ).to eq( value )
        end

        # test: should have de-provisioned the object
        	#p @myobj.provision(:read, false).inspect 
		#p 'expect( @myobj.provision(:read, false) ).not_to match(/>#{@myobj.name}</) unless obj == "User"'
        expect( @myobj.provision(:read, false) ).not_to match(/>#{@myobj.name}</) unless obj == "User"
        expect( @myobj.provision(:read, false) ).not_to match(/>#{@myobj.site.countrycode}#{@myobj.site.areacode}#{@myobj.site.localofficecode}#{@myobj.extension}</) if obj == "User"


      end # it "initObj( #{obj}, true, false ) should create the object with the right attributes in the database and de-provision the object, if it was provisioned" do

      it "initObj( obj: #{obj}, shall_exist_on_db: true, shall_exist_on_target: true ) should create the object with the right attributes in the database and provision the object, if it was not yet provisioned" do
  
        # make sure the database does not contain any object of the type obj
        obj.constantize.all.each do |myobject|
          myobject.destroy!
        end
	#@@siteprovisioned = nil

        # make sure the provisioningobject is destroyed on the target (so, we can test, whether init will provision the provisioningobject)
        expect{ @myobj = createObjDB(obj) }.to change(Object.const_get(obj), :count).by(1)
        # create children:
        expect{ @mychildobj = createObjDB(child(obj)) }.to change(Object.const_get(child(obj)), :count).by(1) unless child(obj).nil?

        # Create "Site3" in the database and deprovision it: 
        # i.e. workaround for non-existent synchronization before recursive deletion within the rspec above
        expect{ @mychildobj2 = createObjDB(child(obj), 3) }.to change(Object.const_get(child(obj)), :count).by(1) unless child(obj).nil? if obj=="Customer"
        # workaround part 2: de-provision Site3 
        @mychildobj2.provision(:create, false) unless child(obj).nil? if obj=="Customer"
        @mychildobj2.provision(:destroy, false) unless child(obj).nil? if obj=="Customer"

        # recursively deprovision:
        @myobj.provision(:destroy, false)
        expect( @myobj.provision(:read, false) ).not_to match(/>#{@myobj.name}</) unless obj == "User"
        expect( @myobj.provision(:read, false) ).not_to match(/>#{@myobj.site.countrycode}#{@myobj.site.areacode}#{@myobj.site.localofficecode}#{@myobj.extension}</) if obj == "User"
        # recursively delete from DB:
        @myobj.destroy!
        
        # test: should create an object
        #expect{ initObj( obj, true, false ) }.to change(Object.const_get(obj), :count).by(1)
        expect{ initObj(obj: obj, shall_exist_on_db: true, shall_exist_on_target: true) }.to change(Object.const_get(obj), :count).by(1)
        
        # test: should have created an object with the right attributes:
        @myobj = Object.const_get(obj).last
        defaultParams(obj).each do |key, value|
          	#p "#{key} => #{value}"
          expect( @myobj.send(key) ).to eq( value )
        end

        # test: should have provisioned the object
        	#p @myobj.provision(:read, false).inspect 
        expect( @myobj.provision(:read, false) ).to match(/>#{@myobj.name}</) unless obj == "User"
        expect( @myobj.provision(:read, false) ).to match(/>#{@myobj.site.countrycode}#{@myobj.site.areacode}#{@myobj.site.localofficecode}#{@myobj.extension}</) if obj == "User"


      end # it "initObj( obj: #{obj}, shall_exist_on_db: true, shall_exist_on_target: true ) should create the object with the right attributes in the database and provision the object, if it was not yet provisioned" do

      it "initObj( obj: #{obj}, shall_exist_on_db: false, shall_exist_on_target: true ) should remove the object from the database and provision the object with the right attributes on the target, if it was not yet provisioned" do
  
        # make sure the database does not contain any object of the type obj
        obj.constantize.all.each do |myobject|
          myobject.destroy!
        end
	#@@siteprovisioned = nil

        # make sure the provisioningobject is destroyed on the target (so, we can test, whether init will provision the provisioningobject)
        expect{ @myobj = createObjDB(obj) }.to change(Object.const_get(obj), :count).by(1)
        # create children:
        expect{ @mychildobj = createObjDB(child(obj), 0) }.to change(Object.const_get(child(obj)), :count).by(1) unless child(obj).nil? || defaultParams(child(obj), 0).nil?
        expect{ @mychildobj = createObjDB(child(obj), 1) }.to change(Object.const_get(child(obj)), :count).by(1) unless child(obj).nil? || defaultParams(child(obj), 1).nil? || child(obj) == "Site" # for sites, paramsSet 1 is a duplicate name to paramsSet2 for testing sync. Therefore, it will never be provisioned on the target
        expect{ @mychildobj = createObjDB(child(obj), 2) }.to change(Object.const_get(child(obj)), :count).by(1) unless child(obj).nil? || defaultParams(child(obj), 2).nil?
        expect{ @mychildobj = createObjDB(child(obj), 3) }.to change(Object.const_get(child(obj)), :count).by(1) unless child(obj).nil? || defaultParams(child(obj), 3).nil?
        #expect{ @mychildobj = createObjDB(child(obj), 2) }.to change(Object.const_get(child(obj)), :count).by(1) unless child(obj).nil?
        # recursively deprovision:
        @myobj.provision(:destroy, false)
        expect( @myobj.provision(:read, false) ).not_to match(/>#{@myobj.name}</) unless obj == "User"
        expect( @myobj.provision(:read, false) ).not_to match(/>#{@myobj.site.countrycode}#{@myobj.site.areacode}#{@myobj.site.localofficecode}#{@myobj.extension}</) if obj == "User"
        # recursively delete from DB:
        @myobj.destroy!
        
        # test: should create an object
        #expect{ initObj( obj, true, false ) }.to change(Object.const_get(obj), :count).by(1)
        expect{ initObj(obj: obj, shall_exist_on_db: false, shall_exist_on_target: true) }.to change(Object.const_get(obj), :count).by(0)
        
#        # test: should have created an object with the right attributes:
#        @myobj = Object.const_get(obj).last
#        defaultParams(obj).each do |key, value|
#          	#p "#{key} => #{value}"
#          expect( @myobj.send(key) ).to eq( value )
#        end

        # test: should have provisioned the object
        	#p @myobj.provision(:read, false).inspect 
        expect( @myobj.provision(:read, false) ).to match(/>#{@myobj.name}</) unless obj == "User"
        expect( @myobj.provision(:read, false) ).to match(/>#{@myobj.site.countrycode}#{@myobj.site.areacode}#{@myobj.site.localofficecode}#{@myobj.extension}</) if obj == "User"

      end # it "initObj( #{obj}, true, false ) should create the object with the right attributes in the database and de-provision the object, if it was provisioned" do


    end # describe "initObj(#{obj}) via model" do

  #end # ???????????????????

    describe "sync(#{obj}) via model" do
      before do
        @myobj = createObjDB(obj)
        #@myobj.provision(:destroy)
      end

      [true, false].each do |async|
      describe "in async=#{async} mode" do
        it "should update the status of the object to 'provisioned' if it is provisioned on the target system already" do
          # init
		  #@@customerprovisioned = nil
		  #@@siteprovisioned = nil
		  #@@userprovisioned = nil
          # reset @@probisined in HttpPostRequest
          persistent_hashes = PersistentHash.where(name: "HttpPostRequest.provisioned")
          persistent_hashes[0].destroy! if persistent_hashes.count == 1

          @myobj.destroy!
          @myobj = createObjDB(obj, defaultParams(obj, 0) ) #createObjDB(obj, paramsSet = nil, i = 1 )
          @myobj.provision(:destroy, false)
          @myobj.provision(:create, false)
          # make sure the object has been created with data set i=0
          if obj == "Site"
            defaultParams(obj, 0).each do |key, value|
            	  #p "0-----------------------------" + key.inspect
          	  #p "#{key} => #{value}"
          	  #p "key.class.name=#{key.class.name}"
              expect( @myobj.send(key) ).to eq( value )
            end
          end
          @myobj.update_attribute(:status, "bla blub")
          @myobj.update_attributes(defaultParams(obj, 1)) if obj == "Site"
          
          # make sure that @myobj is not out of sync with the database:
          @myobj = @myobj.class.find(@myobj.id)

          expect( @myobj.status ).to match(/bla blub/) 
          if obj == "Site"
            # make sure the object has been updated with data set i=1
            defaultParams(obj, 1).each do |key, value|
            	  #p "1-----------------------------" + key.inspect
          	  #p "#{key} => #{value}"
          	  #p "key.class.name=#{key.class.name}"
              expect( @myobj.send(key) ).to eq( value ) unless key == :name # name must be the same
            end  
            # and that it differs from the original values (apart from the name, which must be the same):
            defaultParams(obj, 0).each do |key, value|
                  #p "2-----------------------------" + key.inspect
          	  #p "#{key} => #{value}"
          	  #p "key.class.name=#{key.class.name}"
              expect( @myobj.send(key) ).not_to eq( value ) unless key == :name # name may be the same in the two data sets
            end
          end

          # make sure that @myobj is not out of sync with the database:
          @myobj = @myobj.class.find(@myobj.id)

          expect( @myobj.status ).to match(/bla blub/) 
  
	  #p "@@customerprovisioned = " + @@customerprovisioned.inspect
	  #p "@@siteprovisioned = " + @@siteprovisioned.inspect
	  #p "@@userprovisioned = " + @@userprovisioned.inspect
          # test
  
	  Delayed::Worker.delay_jobs = true

          # simulate that HttpPostRequest.provisioned is running in the background with its own memory space:
          #HttpPostRequest.provisioned={} if async
          HttpPostRequest.remove_class_variables if async

          sync(@myobj, async)

          # run Delayed Jobs
          expect( Delayed::Worker.new.work_off ).to eq [1, 0] if async
          #sleep 60.seconds
		  #p defaultParams(obj).inspect

          # make sure that @myobj is not out of sync with the database:
          @myobj = @myobj.class.find(@myobj.id)

          defaultParams(obj).each do |key, value|
          	  #p "#{key} => #{value}"
          	  #p "key.class.name=#{key.class.name}"
            expect( @myobj.send(key) ).to eq( value)
          end
          expect( @myobj.status ).to match(/provisioning successful \(synchronized\)|provisioning successful \(synchronized all parameters\)|provisioning successful \(verified existence\)/) 
          
  
        end # it "should update the status of the object to 'provisioned' if it is provisioned on the target system already" do
      end # describe "in async=#{async} mode" do
      end # [true, false].each do |async|

     if obj == "Site" || obj == "User" || obj == "Customer"
      it "should synchronize the index with the objects found on the target system, if called with a specially named dummy object", obsolete: true do
        # if called with dummy object (id==nil), objects found on the target should be synchronized with the database
        initObj(obj: obj, shall_exist_on_db: false, shall_exist_on_target: true)
        # set default paramsSet:
        paramsSet = defaultParams(obj, 0)
        # create parent, if it does not exist and add the parent id to the paramsSet:
        myParent = createObjDB(parent(obj)) unless parent(obj).nil?
        paramsSet = paramsSet.merge!("#{parent(obj).downcase}_id".to_sym => myParent.id) unless parent(obj).nil?

        # make sure no object existis on the datebase:
        expect( obj.constantize.where( paramsSet ).count).to be(0)
        expect( obj.constantize.where( extension: paramsSet[:extension], site: myParent).count ).to be(0) if obj == "User"
        
        #special name for Customer dummy:
        paramsSetDummy = paramsSet.clone
        paramsSetDummy[:name] = '_sync_dummyCustomer_________________3426' if obj == "Customer"
		#abort paramsSet.inspect
        # create the object but do not save it:
        #dummyObj = obj.constantize.new(paramsSet)
        expect{ @dummyObj = obj.constantize.new(paramsSetDummy) }.to change(Object.const_get(obj), :count).by(0) 
 
        # because us async sync, the dummyObj needs to be saved (delayed_jobs cannot work on transient data):
        expect{ @dummyObj.save!(validate: false) }.to change(Object.const_get(obj), :count).by(1) if obj == "Customer"
        #dummyObj = Object.const_get(obj).last # 
		#abort @dummyObj.inspect
		#abort sync( @dummyObj ).inspect

        # tests:
        # 1) sync should create an object in the DB:
        expect{ sync( @dummyObj ) }.to change(Object.const_get(obj), :count).by_at_least(1)

		#abort obj.constantize.all.inspect
        # 2) test whether the synced object has the expected parameters
        # 2.1 Sites should match exactly
                #p ">>>>>>>>>>>>>>>>>>>>>>" + paramsSet.inspect + "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                #p ">>>>>>>>>>>>>>>>>>>>>>" +  obj.constantize.all.inspect  + "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        expect( obj.constantize.where( paramsSet ).count).to be(1) if obj == "Site"
		#abort obj.constantize.where( paramsSet ).inspect
        # 2.2 non-Sites should not match yet, since they are not fully synchronized yet:
        expect( obj.constantize.where( paramsSet ).count).to be(0) if obj != "Site" 
        # 2.3 but a new customer with name ExampleCustomerV8 should be created:
        expect( obj.constantize.where( name: paramsSet[:name] ).count ).to be(1) if obj == "Customer"
        # 2.4 and a User with the right extension should be present in the DB now:
        expect( obj.constantize.where( extension: paramsSet[:extension], site: myParent).count ).to be(1) if obj == "User"
		#syncedObject = Object.const_get(obj).last
		#abort syncedObject.inspect

      end # it "should synchronize the index with the objects found on the target system" do 
     end #if obj == "Site"
    end # describe "sync(#{obj}) via model" do
    
    ['model', 'view'].each do |testTarget|
      # skip the view test, if the synchronizebutton is not present:
      next if testTarget == 'view' && ENV["WEBPORTAL_SYNCHRONIZEBUTTON_VISIBLE"] == "false"
      
      describe "synchronize individual #{obj} for testTarget == #{testTarget}" do
        # TODO: add the individual test, similar to the syn(obj) tests here

      end # describe "synchronize individual #{obj} for testTarget == #{testTarget}" do

      describe "synchronize all #{obj.pluralize} for testTarget == #{testTarget}" do
       if obj == "Customer" || obj == "Site" || obj == "User"
        it "should synchronize the index with the #{obj} objects found on the target system" do
          # create an object that is on the target and not in the DB (shouldl be synchronized to the DB at the end)
          Delayed::Worker.delay_jobs = false
          
          myClass = Object.const_get(myObject(obj))
                #abort myClass.inspect
                
          provisionedObjectToBeCreatedOnDB = initObj(obj: obj, shall_exist_on_db: false, shall_exist_on_target: true)
                #abort myClass.all.inspect      
          # check that initObj was working correctly and the object is not in the database:
          #expect( Customer.where(defaultParams(obj)).count ).to be(0)
          expect( Object.const_get(myObject(obj)).where(defaultParams(obj)).count ).to be(0) 
          expect(page.html.gsub(/[\n\t]/, '')).not_to match(/#{defaultParams(obj)[:name]}/) if ENV["WEBPORTAL_SYNCHRONIZEBUTTON_VISIBLE"] == "true"
          
          # create an object that is on the db, marked as provisioned, but not found on the target (should be marked as not provisioned at the end)

          notProvisionedObjectToBeSetToNotProvisioned = initObj(obj: obj, shall_exist_on_db: true, shall_exist_on_target: false, paramsSet: defaultParams(obj, 2))
			           #abort myClass.all.inspect
          notProvisionedObjectToBeSetToNotProvisioned.update_attribute(:status, 'provisioned successfully')
                  #abort myClass.all.inspect
                  
          # the object should not be in status "not provisioned": 
          expect( notProvisionedObjectToBeSetToNotProvisioned.provisioned? ).to be(true)      
          expect( notProvisionedObjectToBeSetToNotProvisioned.status ).not_to match(/not provisioned/)
          
          # create an object that is already on the database with the right provisioning status:
          provisionedObjectAlreadyOnDB = initObj(obj: obj, shall_exist_on_db: true, shall_exist_on_target: true, paramsSet: defaultParams(obj, 3))
			#abort provisionedObjectAlreadyOnDB.inspect
          expect( provisionedObjectAlreadyOnDB.provisioned? ).to be(true)
          # status should not change, if possible, so let us remember the status, so we can compare later
          status_before_provisionedObjectAlreadyOnDB = provisionedObjectAlreadyOnDB.status    
          
          #initObj(obj: obj, shall_exist_on_db: true, shall_exist_on_target: false)
          

          if testTarget == 'model'
            # before 'clicking' "Synchronize", the object should not be present on the index page:
            delta = myClass.where(extension: defaultParams(obj)[:extension]).count if obj == "User"
            delta = myClass.where(name: defaultParams(obj)[:name]).count if obj != "User"             
            #expect( myClass.where(extension: defaultParams(obj)[:extension]).count ).to be(0) if obj == "User"
            #expect( myClass.where(name: defaultParams(obj)[:name]).count ).to be(0) if obj != "User"           
            
            # 'clicking' the "Synchronize" link should increase the number of objects by 1 or more:
			             #abort myClass.all.inspect
            expect{ myClass.synchronizeAll(nil, false, false, true) }.to change(Object.const_get(obj), :count).by_at_least(1)
			             #abort myClass.all.inspect
            
            # after 'clicking' "Synchronize", the object should  be present on the index page:  
            delta = myClass.where(extension: defaultParams(obj)[:extension]).count - delta if obj == "User"
            delta = myClass.where(name: defaultParams(obj)[:name]).count - delta if obj != "User"
            expect( delta ).to be > 0
                       
          elsif testTarget == 'view'
            # visit the index page:
            visit provisioningobjects_path(obj)
            
            # before clicking "Synchronize", the object should not be present on the index page:            
            expect(page.html.gsub(/[\n\t]/, '')).not_to match(/#{defaultParams(obj)[:extension]}/) if obj == "User"
            expect(page.html.gsub(/[\n\t]/, '')).not_to match(/#{defaultParams(obj)[:name]}/) unless obj == "User"

            # the "Synchronize" link should be present:
            expect(page).to have_link( "Synchronize #{obj}s" ) #, href: synchronize_provisioningobjects_path(obj) )

            # clicking the "Synchronize" link should increase the number of objects by 1 or more:
            expect{ click_link "Synchronize #{obj}s" }.to change(Object.const_get(obj), :count).by_at_least(1)
            
            # after clicking "Synchronize", the object should  be present on the index page:  
            expect(page.html.gsub(/[\n\t]/, '')).to match(/#{defaultParams(obj)[:extension]}/) if obj == "User"
            expect(page.html.gsub(/[\n\t]/, '')).to match(/#{defaultParams(obj)[:name]}/) unless obj == "User"
          end
          
          # need to reload the data from database (why?)
          notProvisionedObjectToBeSetToNotProvisioned.reload
                #abort myClass.all.inspect
          # the object now should be in status "not provisioned"  :       
          expect( notProvisionedObjectToBeSetToNotProvisioned.provisioned? ).to be(false)
          expect( notProvisionedObjectToBeSetToNotProvisioned.status ).to match(/not provisioned/)
          
                #abort myClass.all.inspect
          # needs to be found on the database:
                #abort provisionedObjectToBeCreatedOnDB.inspect
                #abort myClass.all.inspect
          provisionedObjectToBeCreatedOnDB = myClass.where(extension: provisionedObjectToBeCreatedOnDB.extension)[0] if myClass == User
          provisionedObjectToBeCreatedOnDB = myClass.where(name: provisionedObjectToBeCreatedOnDB.name)[0] unless myClass == User
          
                #abort myClass.all.inspect
                #abort provisionedObjectToBeCreatedOnDB.inspect
          expect( provisionedObjectToBeCreatedOnDB.provisioned? ).to be(true)
          

                
          broken = true # broken for Users and Sites, since a List User or Show Site will only show a static list of Users/Sites
          broken = false if obj == "Customer" # this has been fixed in lib/http_post_request.rb for Customers
          unless broken
          # already correct entry should still be correct:          
            # needs to be reloaded from the DB:
             provisionedObjectAlreadyOnDB.reload    
                  #abort  provisionedObjectAlreadyOnDB.inspect
                  #abort myClass.all.inspect
            expect( provisionedObjectAlreadyOnDB.provisioned? ).to be(true)
            status_before_provisionedObjectAlreadyOnDB = status_before_provisionedObjectAlreadyOnDB.gsub('(', '\(').gsub(')', '\)')
            expect( provisionedObjectAlreadyOnDB.status ).to match(/\A#{status_before_provisionedObjectAlreadyOnDB}\Z/)
          end
          
        end # it "should synchronize the index with the objects found on the target system" do
       end # if obj == "Customer" || obj == "Site" || obj == "User"
      end # describe "synchronize all #{obj} via testTarget = '#{testTarget}" do
    end # ['model', 'view'].each do |testTarget| 

    describe "index" do
      before(:each) do
        createObjDB(obj, 0)
        createObjDB(obj, 2)
        visit provisioningobjects_path(obj)  
      end
      # not needed:
      subject { page }
    
      # "should have the header 'Customers'"
      it "should have the header '#{myObjects(obj)}'" do
        # this works:
        #visit provisioningobjects_path(obj)
                #abort provisioningobjects_path(obj).inspect
		#abort page.html.gsub(/[\n\t]/, '')
        expect(page).to have_selector('h1', text: obj)
      end
      
      #  "should have link to 'New Customer'"
      it "should have link to 'New #{obj}'" do     
        #expect(page).to have_link( 'New Customer', href: new_customer_path )
                #p page.html.gsub(/[\n\t]/, '')

        # TODO: need to find a way to have the same expect command for all provisioningobjects
        expect(page).to have_link( "New #{obj}", href: new_provisioningobject_path(obj) + '?per_page=all') #unless obj == "Site"
        #expect(page).to have_link( "New #{obj}", href: new_provisioningobject_path(obj) ) if obj == "Site"
      end
      
      #   "link to 'New Customer' leads to correct page"
      its "link to 'New #{obj}' leads to correct page" do
        click_link "New #{obj}"
        expect(page).to have_selector('h1', text: "New #{obj}")    
      end    
    end # of describe "index" do

    describe "New #{obj}" do
      before { 
        # de-provision and delete customer, if it exists already:
        destroyObjectByName(obj)
        visit new_provisioningobject_path(obj) 
        }
      
      it "should have the header 'New #{obj}'" do
        expect(page).to have_selector('h1', text: "New #{obj}")
      end
      
      #its "Cancel button in the web form leads to the Customers index page" do
      its "Cancel button in the web form leads to the #{myObjects(obj)} index page" do
        #find html tag with class=index. Within this tag, find and click link 'Cancel' 
        #first('.index').click_link('Cancel')
    #p page.html.gsub(/[\n\t]/, '')
        click_link('Cancel')
        expect(page).to have_selector('h1', text: "#{myObjects(obj)}")    
      end
    end # of describe "New Customer" do

    #describe "Create Customer" do
    describe "Create #{obj}" do
      before { visit new_provisioningobject_path(obj) }
      let(:submit) { "Save" }
  
      describe "with invalid information" do
        #it "should not create a customer" do
        it "should not create a #{obj}" do
          #expect { click_button submit, match: :first }.not_to change(Customer, :count)
          expect { click_button submit, match: :first }.not_to change(Object.const_get(obj), :count)
          #expect { click_button submit, match: :first }.not_to change(myProvisioningobject(obj), :count)
        end

        if obj == "Customer" or obj == "Site"
          describe "with unicode characters (Umlauts) in the name" do
            it "should not create a #{obj} and throw an error containing 'prohibited this'" do
              #expect { click_button submit, match: :first }.not_to change(Customer, :count)
              fillFormForNewObject(obj, "Umlaut#{obj}Ü")
              expect { click_button submit, match: :first }.not_to change(Object.const_get(obj), :count)
	      expect(page.html.gsub(/[\n\t]/, '')).to match(/prohibited this/)
              #expect { click_button submit, match: :first }.not_to change(myProvisioningobject(obj), :count)
            end
	  end
	end
        
        #it "should not create a customer on second 'Save' button" do
        it "should not create a #{obj} on 2nd 'Save' button", broken: true do
          expect { first('.index').click_button submit, match: :first }.not_to change(myProvisioningobject(obj), :count)
        end
        
        it "should throw an error message" do
#p page.html.gsub(/[\n\t]/, '')
          click_button submit, match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/prohibited this/)
        end

        describe "with duplicate data" do
          #it "should not create a customer" do
          it "should not create a #{obj}" do
            createObject(obj)
            expect { createObject(obj) }.not_to change(myProvisioningobject(obj), :count) 
          end
          
          it "should should throw certain error messages" do
            createObject(obj)
            createObject(obj)
            if obj=="Site"
              #p "============================"
              #p page.html.gsub(/[\n\t]/, '').gsub(/\/\//, '').inspect
              expect(page).to have_selector('li', text: "#{:name.capitalize} is already taken for this customer")
              expect(page.html.gsub(/[\n\t]/, '')).to match(/#{:mainextension.capitalize} \[10000\] is already taken for target/)
              expect(page.html.gsub(/[\n\t]/, '')).to match(/#{:gatewayIP.capitalize} \[47\.68\.190\.57\] is already taken for target/) unless $setgatewayip == false
            end
            if obj=="User"
              #p "============================"
              #p page.html.gsub(/[\n\t]/, '').inspect
              expect(page).to have_selector('li', text: "Extension is already taken for this site")
            end
          end # it "should should throw certain error messages" do
        end # describe "with duplicate data" do
        
        # TODO: activate the test below and then implement https://www.railstutorial.org/book/_single-page#sec-uniqueness_validation 
        #describe "with case-insensitive duplicate name" do
        #  it "should not create a customer" do
        #    #createTarget
        #    customerName = "CCCCust"
        #    createCustomer customerName
        #    expect { createCustomer customerName.to_lower }.not_to change(Customer, :count)       
        #  end
        #end
      end # describe "with invalid information" do
      
#    end #describe "Create #{obj}" do 
#    
#    #describe "Create Customer" do
#    describe "Create #{obj}" do
#      before { visit new_provisioningobject_path(obj) }
#      let(:submit) { "Save" }
  
      describe "with valid factory information" do

        # TODO: also make it available for obj="Site" and obj="User"
        if obj == "Customer"
          it "has a valid factory" do
            expect( FactoryGirl.create(:target) ).to be_valid if obj == "Customer"  # only test once: for obj = "Customer"
            expect( FactoryGirl.create(:customer) ).to be_valid
            # TODO: not yet available:
            # expect( FactoryGirl.create(:site) ).to be_valid if obj == "Site"
            # expect( FactoryGirl.create(:user) ).to be_valid if obj == "User"
          end

          it "should add a #{obj} to the database (FactoryGirlTest)" do
            FactoryGirl.create(:target)
            delta = myProvisioningobject(obj).count
              #p myProvisioningobject(obj).count.to_s + "<<<<<<<<<<<<<<<<<<<<< delta before"
            #FactoryGirl.attributes_for(:customer, name: "dhgkshk")
            FactoryGirl.create(:customer)
              #p  "myProvisioningobject(obj).all.inspect = #{myProvisioningobject(obj).all.inspect}"
            customer = myProvisioningobject(obj).last
              #p customer.name + "<<<<<<<<<<<<<<<< customer.name"
            delta = myProvisioningobject(obj).count - delta
              #p delta.to_s + "<<<<<<<<<<<<<<<<<<<<< delta after"
            expect(delta).to eq(1)
                  #expect(FactoryGirl.create(:customer)).to change(Customer, :count).by(1)
                  #expect(FactoryGirl.build(:customer)).to change(Customer, :count).by(1)
              #p myProvisioningobject(obj).count.to_s + "<<<<<<<<<<<<<<<<<<<<<"
          end
        end # if obj == "Customer"

      end # describe "with valid factory information"

      describe "with valid information" do
        # does not work yet (is just ignored):
        #let(:target) { FactoryGirls.create(:target) }
        before do
          #createTarget
	  Delayed::Worker.delay_jobs = false
          createObject(obj)
	  #if /V7R1/.match($targetname)
          #  # correct Sitecode for V7R1 targets:
          #  expect(page.html.gsub(/[\n\t]/, '')).to match(/must not be empty for V7R1 targets/)
          #  fill_in "Sitecode",         with: "99821"
          #  click_button submit, match: :first
          #end
#p page.html.gsub(/[\n\t]/, '')
          destroyObjectByNameRecursive(obj)
          fillFormForNewObject(obj)
          if /V7R1/.match($targetname) && obj == "Site"
            click_button submit, match: :first
            expect(page.html.gsub(/[\n\t]/, '')).to match(/must not be empty for V7R1 targets/)
            fill_in "Sitecode",         with: "99821"
          end
        end

        it "should create a #{obj} (1st 'Save' button)" do
          expect { click_button submit, match: :first }.to change(myProvisioningobject(obj), :count).by(1) 
        end
        
        it "should create a #{obj} (2nd 'Save' button)", broken: true do
          expect { first('.index').click_button submit, match: :first }.to change(myProvisioningobject(obj), :count).by(1)
        end
       
        describe "Provisioning", provisioning: true do
          it "should create a #{obj} with status 'provisioning success'" do
            # synchronous operation, so we will get deterministic test results:         
            Delayed::Worker.delay_jobs = false
            
            	# for debugging:
            	#p page.html.gsub(/[\n\t]/, '')
            click_button submit, match: :first
#abort page.html.gsub(/[\n\t]/, '')
            
            # TODO: it should redirect to customer_path(created_customer_id)

            # redirected page should show provisioning success
            expect(page.html.gsub(/[\n\t]/, '')).to match(/provisioning success/)
            
            # /customers/<id> should show provisioning success
            myObjects = myProvisioningobject(obj).where(name: $customerName ) if obj == "Customer"
            myObjects = myProvisioningobject(obj).where(name: "Example#{obj}" ) unless obj == "User" || obj == "Customer"
            myObjects = myProvisioningobject(obj).where(Extension: "30800" ) if obj == "User"
            visit provisioningobject_path(myObjects[0])
            # for debugging:
            #p page.html.gsub(/[\n\t]/, '')
            expect( page.html.gsub(/[\n\t]/, '')).to match(/provisioning success/)                    
          end
          
          it "should create one or more provisioning tasks" do
            expect { click_button submit, match: :first }.to change(Provisioning, :count).by_at_least(1)         
          end
          
          it "should create one or more provisioning tasks (2nd 'Save' button)", broken: true do
            expect { first('.index').click_button submit, match: :first }.to change(Provisioning, :count).by_at_least(1)         
          end
          
          #it "should create a provisioning task with action='action=Add Customer' and 'customerName=ExampleCustomerV8'" do
          it "should create a provisioning task with action='action=Add #{obj}' and 'customerName=#{$customerName} etc." do
            mycountbefore = Provisioning.all.count
            click_button submit, match: :first
            foundAction = nil
            createdProvisioningTasks = Provisioning.last(Provisioning.all.count - mycountbefore).each do |task|
              if task.action.match(/action=Add #{obj}/)
                foundAction = task.action
                break;
              end
	    end
            expect( foundAction ).not_to be( nil )
            # should is deprecated, if not enabled explicitly:
            #expect( foundAction ).to match(/action=Add #{obj}/)
            expect( foundAction ).to match(/action=Add #{obj}/)
            case obj
              when /Customer/
                expect( foundAction ).to match(/customerName=#{$customerName}/)
              when /Site/
                expect( foundAction ).to match(/customerName=#{$customerName}/)
                expect( foundAction ).to match(/SiteName=ExampleSite/)
                #expect( foundAction ).to match(/SC=99821/)
                expect( foundAction ).to match(/CC=49/)
                expect( foundAction ).to match(/AC=99/)
                expect( foundAction ).to match(/LOC=7007/)
                expect( foundAction ).to match(/XLen=5/)
                expect( foundAction ).to match(/EndpointDefaultHomeDnXtension=10000/)
              when /User/
                expect( foundAction ).to match(/customerName=#{$customerName}/)
                expect( foundAction ).to match(/SiteName=ExampleSite/)
                expect( foundAction ).to match(/X=30800/)
                expect( foundAction ).to match(/givenName=Oliver/)
                expect( foundAction ).to match(/familyName=Veits/)
                expect( foundAction ).to match(/assignedEmail=oliver.veits@company.com/)
                expect( foundAction ).to match(/imAddress=oliver.veits@company.com/)
            end
          end
          
          #it "should create a provisioning task that finishes successfully or throws an Error 'Customer exists already'" do
          it "should create a provisioning task that finishes successfully or it should throw an Error 'exists already'" do
            Delayed::Worker.delay_jobs = false
            click_button submit, match: :first
            # find last Add Provisioning task
            createdProvisioningTask = Provisioning.where('action LIKE ?', "%action=Add #{obj}%").last
#            begin
              expect( createdProvisioningTask.status ).to match(/finished successfully|#{obj}/) if obj == "Customer"
              expect( createdProvisioningTask.status ).to match(/finished successfully|exists already/) if obj == "Site"
              expect( createdProvisioningTask.status ).to match(/finished successfully|phone number is in use already/) if obj == "User"
#            rescue
#                expect( createdProvisioningTask.status ).to match(/#{obj} exists already/) if obj == "Customer"
#                expect( createdProvisioningTask.status ).to match(/exists already/) if obj == "Site"
#                expect( createdProvisioningTask.status ).to match(/phone number is in use already/) if obj == "User"
#            end
          end  

          it "should save a #{obj} with status '#{expectedProvisionStatus}'" do
            Delayed::Worker.delay_jobs = true
            click_button submit, match: :first
            expect(page.html.gsub(/[\n\t]/, '')).to match(/#{expectedProvisionStatus}/)
            # flash:
            expect(page.html.gsub(/[\n\t]/, '')).to match(/#{expectedProvisionFlash}/)
          end

          #if obj == 'Customer'
          it "with provisioning time set to ad hoc, should save an #{obj} with status 'not provisioned'" do
            Delayed::Worker.delay_jobs = true
            select Provisioningobject::PROVISIONINGTIME_AD_HOC, :from => "#{myobject(obj)}[provisioningtime]"
#p page.html.gsub(/[\n\t]/, '')
            click_button submit, match: :first
            expect(page.html.gsub(/[\n\t]/, '')).to match(/not provisioned/)
            expect(page.html.gsub(/[\n\t]/, '')).to match(/is created and can be provisioned ad hoc/)
          end
          #end


        end # describe "Provisioning" do
      end # describe "with valid information" do 

      describe "that exists already on target system", simulationbroken: true do
        before do
	  Delayed::Worker.delay_jobs = false
          createObject(obj)
	  #p page.html.gsub(/[\n\t]/, '')

          # destroy the object for the case it is in the database only, but not provisionined on the target system:
	  destroyObjectByNameRecursive(obj)
	  #p page.html.gsub(/[\n\t]/, '')

          # create the object, so the provisioning of the object is triggered on the target system
          myURL = createObject(obj)
	  #p page.html.gsub(/[\n\t]/, '')

	  # delete the object from the database:
	  if myURL.nil?
	    abort "createObject(obj) did not return the correct URL. Full page content: " + page.html.gsub(/[\n\t]/, '')
	  else
            deleteObjectURLfromDB(obj, myURL)
	  end
          # now the object should exist on the target system but not on the DB

	  # define fill in create form with different data than fillFormForNewObject 
          # (needed for the test cases that are syncing back from target system to the database)
          fillFormForNewObject(obj)
	  if obj == "Site"
  	    select "44", :from => "site[countrycode]" # 44 instead of 49
  	    fill_in "Areacode",         with: "98"    # 98 instead of 99
  	    fill_in "Localofficecode",         with: "8008"  # 8008 instead of 7007
  	    fill_in "Extensionlength",         with: "4"     # 4 instead of 5
  	    fill_in "Mainextension",         with: "2222"    # 2222 insted of 10000
  	    fill_in "Gatewayip",         with: "39.58.28.92" unless $setgatewayip == false # 39.58.28.92 instead of 47.68.190.57
          end
        end

	let(:submit) { "Save" }

        it "should create a #{obj} with status 'provisioning successful (synchronized all parameters)' or 'provisioning successful (verified existence)'" do
          Delayed::Worker.delay_jobs = false
          click_button submit, match: :first
          if /V7R1/.match($targetname) && page.html.gsub(/[\n\t]/, '').match("Sitecode must not be empty for V7R1 targets")
            fill_in "Sitecode",         with: "99821"
            click_button 'Save', match: :first
          end

          expect(page.html.gsub(/[\n\t]/, '')).to match(/provisioning successful \(synchronized all parameters\)|provisioning successful \(verified existence\)/)
        end

	if obj == "Site"
          it "should update the #{obj} in the DB according to the data found in the target system" do
            Delayed::Worker.delay_jobs = false
            click_button submit, match: :first
            if /V7R1/.match($targetname) && page.html.gsub(/[\n\t]/, '').match("Sitecode must not be empty for V7R1 targets")
              fill_in "Sitecode",         with: "99821"
              click_button 'Save', match: :first
            end      
	    # TODO: add countrycode, areacode, etc. for the obj "Site"
	    #p page.html.gsub(/[\n\t]/, '')
            if obj == "Site"
              expect(page.html.gsub(/[\n\t]/, '')).to match(/99/) 
              expect(page.html.gsub(/[\n\t]/, '')).to match(/7007/) 
              expect(page.html.gsub(/[\n\t]/, '')).to match(/5/) 
              expect(page.html.gsub(/[\n\t]/, '')).to match(/10000/) 
              expect(page.html.gsub(/[\n\t]/, '')).to match(/47.68.190.57/)  unless $setgatewayip == false
	    end
          end
	end
      end #describe "with valid information" do
    end # describe "Create #{obj}" do 
    
    #describe "Destroy Customer" do
    describe "Destroy #{obj}" do
      describe "Delete #{obj} from database" do
        before {
          Delayed::Worker.delay_jobs = false
	  createObject(obj)
	  #fillFormForNewObject(obj)
        }
	
	let(:submit) { "Delete #{obj}" }
        let(:submit2) { "Destroy" }

        it "should delete an #{obj} from the database, if the status contains 'was already de-provisioned'" do
          myObjects = myProvisioningobject(obj).where(name: $customerName ) if obj == "Customer"
          myObjects = myProvisioningobject(obj).where(name: "Example#{obj}" ) unless obj == "User" || obj == "Customer"
          myObjects = myProvisioningobject(obj).where(Extension: "30800" ) if obj == "User"
          myObjects[0].update_attributes!(:status => 'deletion failed: was already de-provisioned (press "Destroy" or "Delete" again to remove from database)')
      #p page.html.gsub(/[\n\t]/, '')
      #expect(page.html.gsub(/[\n\t]/, '')).to match(/Delete Site/)
	  expect { click_link submit, match: :first }.to change(myProvisioningobject(obj), :count).by(-1)
      #p page.html.gsub(/[\n\t]/, '')
          expect(page.html.gsub(/[\n\t]/, '')).to match(/deleted/)  # flash
        end
      end # describe "Delete #{obj} from database" do

      #describe "De-Provision Customer" do
      describe "De-Provision #{obj}", provisioning: true do
        before {
          # synchronous handling to make test results more deterministic
          Delayed::Worker.delay_jobs = false
          #createTarget
          begin
            # TODO: Still broken?: if an object is in the database, but not provisioned, the object will be deleted from the DB instead of performing de-provisioning
            # TODO: better make sure the object is provisioned

            createObject(obj)
            # DONE: need to de-provision any children befre trying to de-provision the object
            #       idea: in case of a obj=="Customer", createObject("Site") and destroyObjectByName("Site")
	    #       better idea: createObject of the child, so the children will be found and de-provisioned recursively
	    createObject("Site") if obj == "Customer"
	    createObject("User") if obj == "Customer" || obj == "Site"

          #rescue
            # go on, if createObject was not successful
          end
          if obj == "Site"
            # TODO: securely find out, if a Site exists on the target system
            #       Note: today, when a site exists already, you might get an error like 'Site Code "99821" exists already'
            #             this leads to the problem that we cannot know, whether this site is already provisioned or not
            #
            #       Workaround for now is to assume that the site is already provisioned and is ready to be deleted.
            #                  for that, we force status = "provisioning success: was already provisioned"
            #
            #createObject("Site", name = "ExampleSite" ) # might fail with an error like 'Site Code "99821" exists already'
            @sites=Site.where(name: 'ExampleSite')
            if @sites.count == 0
              abort "Could not create or find ExampleSite"
            elsif @sites.count > 1
              abort "Too many sites with name \"ExampleSite\""
            else
              @site=@sites[0]
            end
            @site.update_attributes!(:status => "provisioning success: was already provisioned")
          end # if obj == "Site"

          Delayed::Worker.delay_jobs = true
          
          myObjects = myProvisioningobject(obj).where(name: $customerName ) if obj == "Customer"
          myObjects = myProvisioningobject(obj).where(name: "Example#{obj}" ) unless obj == "User" || obj == "Customer"
          myObjects = myProvisioningobject(obj).where(Extension: "30800" ) if obj == "User"
          # TODO: better to perform this count check only on createObject(obj); better to say myObject=createObject(obj) 
          #       and rely on createObject(obj) to return an object only, if the count is 1
          if myObjects.count == 1
            myObjects[0].update_attributes!(:status => "provisioning success: was already provisioned")
            visit provisioningobject_path(myObjects[0])
#abort myObjects[0].inspect
          else
            abort "Found more than one #{obj} with name #{$customerName}" if obj == "Customer"
            abort "Found more than one #{obj} with name Example#{obj}" unless obj == "User" || obj == "Customer"
            abort "Found more than one #{obj} with Extension \"30800\"" unless obj == "User"
          end
          #p page.html.gsub(/[\n\t]/, '')
         
        }
           
        let(:submit) { "Delete #{obj}" }
        let(:submit2) { "Destroy" }
        let(:deprovision) { "De-Provision #{obj}" }
        
	it "should update the status of #{obj} to 'waiting for deletion'" do
          Delayed::Worker.delay_jobs = true
      		#p page.html.gsub(/[\n\t]/, '')
      #expect(page.html.gsub(/[\n\t]/, '')).to match(/Delete Site/)
          #click_link 'De-Provision', match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/De-Provision #{obj}/)
          click_link "De-Provision #{obj}", match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/#{expectedDeprovisionStatus}/)
        end

	it "should update the status of #{obj} '#{expectedDeprovisionStatus}' also for objects that had import errors" do
          myObjects = myProvisioningobject(obj).where(name: $customerName ) if obj == "Customer"
          myObjects = myProvisioningobject(obj).where(name: "Example#{obj}" ) unless obj == "User" || obj == "Customer"
          myObjects = myProvisioningobject(obj).where(Extension: "30800" ) if obj == "User"
	  myObjects[0].update_attributes!(:status => "provisioning failed (import errors)")
          Delayed::Worker.delay_jobs = true
      		#p page.html.gsub(/[\n\t]/, '')
          #click_link 'De-Provision', match: :first
          click_link "De-Provision #{obj}", match: :first
      		#p page.html.gsub(/[\n\t]/, '')
          expect(page.html.gsub(/[\n\t]/, '')).to match(/#{expectedDeprovisionStatus}/)
        end

        # TODO: add destroy use cases
        #       1) De-Provisioning of customer
        #       2) Deletion of customer from database
        it "should de-provision a #{obj} with status 'deletion success'" do
          # synchronous operation, so we will get deterministic test results:         
          Delayed::Worker.delay_jobs = false
          
          #click_link 'De-Provision', match: :first
          click_link deprovision, match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/deletion success/) #have_selector('h1', text: 'Customers')
          
          # /customers/<id> should show deletion success
          myObjects = myProvisioningobject(obj).where(name: $customerName ) if obj == "Customer"
          myObjects = myProvisioningobject(obj).where(name: "Example#{obj}" ) unless obj == "User" || obj == "Customer"
          myObjects = myProvisioningobject(obj).where(Extension: "30800" ) if obj == "User"
          #p customers
          visit provisioningobject_path(myObjects[0])
          # for debugging:
          #p page.html.gsub(/[\n\t]/, '')
          expect( page.html.gsub(/[\n\t]/, '') ).to match(/deletion success/)      
        end
        it "using De-Provision Button in the side bar, should de-provision a #{obj} with status 'deletion success'" do
          # synchronous operation, so we will get deterministic test results:
          Delayed::Worker.delay_jobs = false

          #click_link 'De-Provision', match: :first
          	#p page.html.gsub(/[\n\t]/, '')
          click_link deprovision, match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/deletion success/) #have_selector('h1', text: 'Customers')

          # /customers/<id> should show deletion success
          myObjects = myProvisioningobject(obj).where(name: $customerName ) if obj == "Customer"
          myObjects = myProvisioningobject(obj).where(name: "Example#{obj}" ) unless obj == "User" || obj == "Customer"
          myObjects = myProvisioningobject(obj).where(Extension: "30800" ) if obj == "User"
          #p customers
          visit provisioningobject_path(myObjects[0])
          # for debugging:
          #p page.html.gsub(/[\n\t]/, '')
          expect( page.html.gsub(/[\n\t]/, '') ).to match(/deletion success/)
        end

      end # of describe "De-Provision Customer" do
      
      #describe "Delete Customer from database using manual database seed" do
      # TODO: only supported for Customers. Make it available for Sites and Users.
      if obj == "Customer"
        describe "Delete #{obj} from database using manual database seed" do
          before {
            createCustomerDB_manual(name: "nonProvisionedCust")
            customers = myProvisioningobject(obj).where(name: "nonProvisionedCust" )
                    #p customers.inspect
            #visit customer_path(customers[0])
            visit provisioningobject_path(customers[0])
                    #p page.html.gsub(/[\n\t]/, '')
          }
    
    
          let(:submit) { "Delete #{obj}" }
          let(:submit2) { "Destroy" }
    
          it "should remove a #{obj} from the database, if not found on the target system" do
            Delayed::Worker.delay_jobs = false
      
            expect(page).to have_link("Delete #{obj}")
    
            delta = myProvisioningobject(obj).count
        #p Customer.count.to_s + "<<<<<<<<<<<<<<<<<<<<< Customer.count before click"
            click_link "Delete #{obj}", match: :first
              # replacing by following line causes error "Unable to find link :submit" (why?)
              #click_link :submit
          #p page.html.gsub(/[\n\t]/, '')
        # following line causes an error: 
              #expect(click_link "Delete Customer").to change(Customer, :count).by(-1)
            delta = myProvisioningobject(obj).count - delta
            expect(delta).to eq(-1)
        #p Customer.count.to_s + "<<<<<<<<<<<<<<<<<<<<< Customer.count after click"
          end
        end
      end # if obj == "Customer"
      
      # TODO: only supported for obj="Customer". Make available for "Site" and "User"
      if obj == "Customer"
        #describe "Delete Customer from database" do
        describe "Delete #{obj} from database" do
          
          before {        
            createCustomerDB( "nonProvisionedCust" )
            customers = myProvisioningobject(obj).where(name: "nonProvisionedCust" )
            visit provisioningobject_path(customers[0])
            #p page.html.gsub(/[\n\t]/, '')
           }
             
          let(:submit) { "Delete #{obj}" }
          let(:submit2) { "Destroy" }
          
          it "(working) should remove a customer from the database, if not found on the target system" do
            expect { click_link submit, match: :first }.to change(myProvisioningobject(obj), :count).by(-1)
          end
          
        end # of describe "Delete Customer from database" do
      end #if obj == "Customer"
    end # describe "Destroy #{obj}" do

    #describe "Provision #{obj}" do
    #end # describe "Provision #{obj}" do
    
  end # describe Provisioningobject do
end # objectList.each do |obj|

# rest objectlist: e.g. Array["Provisioning", "Target"]
objectList2.each do |obj| # second objectList
  describe "On target solution '#{targetsolution}'" do
    describe "index" do
      before(:each) do
        #createProvisioningDB_manual
        createObjectDB_manual(obj)
        visit provisioningobjects_path(obj)  
      end
      # not needed:
      subject { page }

      # "should have the header 'Customers'"
      it "should have the header '#{myObjects(obj)}'" do
#p page.html.gsub(/[\n\t]/, '')
        expect(page).to have_selector('h1', text: obj)
        expect(page.html.gsub(/[\n\t]/, '')).to match(/<h[^>]>[\s]*#{obj}/)
      end
    end
  end 
end # objectList2.each do |obj| # second objectList

describe "Customer can be de-provisioned, even if a manually added site is present" do
  # TODO:
  # create Customer, create site, delete site from DB only, so it is still on the target system.
  # it ...
  #   destroyCustomer
  # should be successful, because before deleting, all sites should be synchronized back from the target systems to the PE
end


end # targetsolutionList.each do |targetsolution|


