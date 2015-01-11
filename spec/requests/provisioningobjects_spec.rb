require 'spec_helper'

RSpec.configure do |c|
  #c.filter_run_excluding broken: true #, provisioning: true #, untested: true
end

# if set to false, the Gatewayip input is kept empty, when a new site is created
#$setgatewayip = false
$setgatewayip = true
#TODO: replace with
#      setgatewayipList = Array[nil, "47.68.190.57"]
#      and iterate over the list

$customerName="ExampleCustomerV8"; $target = "OSVIP=192.168.160.7,XPRIP=192.168.160.7,UCIP=192.168.160.7" # OSV V8 (CSL9DEVEL)
#$customerName="ExampleCustomerV7R1"; $target = "OSVIP=192.168.160.4,XPRIP=192.168.113.102,UCIP=192.168.113.101" # OSV V7R1 (CSL9)
#TODO: replace with 
#      versionList = Array["V7R1", "V8"]
#      and iterate over versionList, and set customerName and and target accordingly 

objectList = Array["Customer", "Site", "User"]
#objectList = Array["Customer"]
#objectList = Array["Site"]
#objectList = Array["User"]

def parent(obj)
  case obj
    when /Customer/
      nil
    when /Site/
      "Customer"
    when /User/
      "Site"
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

def provisioningobject_path(thisobject)
  # returns e.g. customer_path
  path = send("#{myobject(thisobject.class.to_s)}_path", thisobject.id)
end

def myProvisioningobject(obj)
  Object.const_get(myObject(obj))
end

def provisioningobjects_path(obj)
  #customers_path
  send("#{myobjects(obj)}_path".to_sym)
end

def new_provisioningobject_path(obj)
  #new_customer_path
  send("new_#{myobject(obj)}_path".to_sym)
end


def createCustomer(name = "" )      
  # add and provision customer "ExampleCustomer with target = TestTarget" 
  obj = "Customer"
  
  fillFormForNewCustomer(name)
#abort "createCustomer: abort"
  click_button 'Save', match: :first 
end

def createSite(name = "ExampleSite" )      
  # add and provision customer "ExampleCustomer with target = TestTarget" 
  fillFormForNewSite(name)
  click_button 'Save', match: :first 
end

def createCustomer(name = $customerName )      
  # add and provision customer "ExampleCustomer with target = TestTarget" 
  fillFormForNewCustomer(name)
  click_button 'Save', match: :first 
end

def createObject(obj, name = "" )        
  fillFormForNewObject(obj, name)
    
  click_button 'Save', match: :first 
  #p page.html.gsub(/[\n\t]/, '').inspect

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

def createCustomerDB_manual( arguments = {} )
  obj = "Customer"
	# default values
	arguments[:name] ||= "nonProvisionedCust"

        target = Target.new(name: "TestTarget", configuration: $target)
	target.save
	#customer = myProvisioningobject(obj).new(name: "nonProvisionedCust", target_id: target.id)
	customer = myProvisioningobject(obj).new(name: "nonProvisionedCust", target_id: target.id, language: Customer::LANGUAGE_GERMAN)
        customer.save!
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
  if Target.where(name: 'TestTarget').count == 0
    Target.create(name: 'TestTarget', configuration: $target)
  end
  visit new_provisioningobject_path("Customer") # for refreshing after creating the target
  fill_in "Name",         with: name        
  select "TestTarget", :from => "customer[target_id]"
  select "german", :from => "customer[language]"
  
  # Note: select "TestTarget" selects the <option value=_whatever_>TestTarget</option> in the following select part of the HTML page:
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
  #fill_in "Sitecode",         with: "99821"
  #fill_in "Countrycode",         with: "49" 
  select "49", :from => "site[countrycode]"
  fill_in "Areacode",         with: "99" 
  fill_in "Localofficecode",         with: "7007" 
  fill_in "Extensionlength",         with: "5" 
  fill_in "Mainextension",         with: "10000" 
  fill_in "Gatewayip",         with: "47.68.190.57" unless $setgatewayip == false
  
  # Note: select "TestTarget" selects the <option value=_whatever_>TestTarget</option> in the following select part of the HTML page:
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
    Delayed::Worker.delay_jobs = delayed_worker_delay_jobs_before
  end
  visit new_provisioningobject_path("User") # for refreshing after creating the target
  #fill_in "Name",         with: name        # not possible, since name input field might not be displayed (depending on the application.yaml file content)
  select "ExampleSite", :from => "user[site_id]"
  fill_in "Extension",         with: "30800"
  fill_in "Givenname",         with: "Oliver" 
  fill_in "Familyname",         with: "Veits" 
  fill_in "Email",         with: "oliver.veits@company.com" 
  
  # Note: select "TestTarget" selects the <option value=_whatever_>TestTarget</option> in the following select part of the HTML page:
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
  if myObjects.count == 1
  #unless myObjects[0].nil?
    Delayed::Worker.delay_jobs = false
    visit provisioningobject_path(myObjects[0])
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
      expect(page).to have_selector('h2', text: Customer.to_s + "s")
    end
  #end
end


describe Site do
    # does not work: it will test the Customer page instead of the Site page:
    #it_behaves_like Customer
end

objectList.each do |obj|
  describe "Provisioningobject #{obj}" do  
    describe "index" do
      before(:each) { visit provisioningobjects_path(obj)  }
      # not needed:
      subject { page }
    
      # "should have the header 'Customers'"
      it "should have the header '#{myObjects(obj)}'" do
        # this works:
        #visit provisioningobjects_path(obj)
        expect(page).to have_selector('h2', text: obj)
      end
      
      #  "should have link to 'New Customer'"
      it "should have link to 'New #{obj}'" do     
        #expect(page).to have_link( 'New Customer', href: new_customer_path )
        expect(page).to have_link( "New #{obj}", href: new_provisioningobject_path(obj) )
      end
      
      #   "link to 'New Customer' leads to correct page"
      its "link to 'New #{obj}' leads to correct page" do
        click_link "New #{obj}"
        expect(page).to have_selector('h2', text: "New #{obj}")    
      end    
    end # of describe "index" do

    describe "New #{obj}" do
      before { 
        # de-provision and delete customer, if it exists already:
        destroyObjectByName(obj)
        visit new_provisioningobject_path(obj) 
        }
      
      it "should have the header 'New #{obj}'" do
        expect(page).to have_selector('h2', text: "New #{obj}")
      end
      
      #its "Cancel button in the left menue leads to the Customers index page" do
      its "Cancel button in the left menue leads to the #{myObjects(obj)} index page" do
        click_link("Cancel", match: :first)
        expect(page).to have_selector('h2', text: "#{myObjects(obj)}")    
      end
      
      #its "Cancel button in the web form leads to the Customers index page" do
      its "Cancel button in the web form leads to the #{myObjects(obj)} index page" do
        #find html tag with class=index. Within this tag, find and click link 'Cancel' 
        first('.index').click_link('Cancel')
        expect(page).to have_selector('h2', text: "#{myObjects(obj)}")    
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
        it "should not create a #{obj} on second 'Save' button" do
          expect { first('.index').click_button submit, match: :first }.not_to change(myProvisioningobject(obj), :count)
        end
        
        it "should throw an error message" do
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
              p page.html.gsub(/[\n\t]/, '').gsub(/\/\//, '').inspect
              expect(page).to have_selector('li', text: "#{:name.capitalize} is already taken for this customer")
              expect(page.html.gsub(/[\n\t]/, '')).to match(/#{:mainextension.capitalize} \[10000\] is already taken for target/)
              expect(page.html.gsub(/[\n\t]/, '')).to match(/#{:gatewayIP.capitalize} \[47\.68\.190\.57\] is already taken for target/) unless $setgatewayip == false
            end
            if obj=="User"
              #p "============================"
              #p page.html.gsub(/[\n\t]/, '').inspect
              expect(page).to have_selector('li', text: "Extension is already taken for this site")
            end
          end
        end
        
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
            FactoryGirl.create(:target).should be_valid if obj == "Customer"  # only test once: for obj = "Customer"
            FactoryGirl.create(:customer).should be_valid
            # TODO: not yet available:
            # FactoryGirl.create(:site).should be_valid if obj == "Site"
            # FactoryGirl.create(:user).should be_valid if obj == "User"
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
          destroyObjectByNameRecursive(obj)
          fillFormForNewObject(obj)
        end

        it "should create a #{obj} (1st 'Save' button)" do
          expect { click_button submit, match: :first }.to change(myProvisioningobject(obj), :count).by(1)       
        end
        
        it "should create a #{obj} (2nd 'Save' button)" do
          expect { first('.index').click_button submit, match: :first }.to change(myProvisioningobject(obj), :count).by(1)
        end
       
        describe "Provisioning", provisioning: true do
          it "should create a #{obj} with status 'provisioning success'" do
            # synchronous operation, so we will get deterministic test results:         
            Delayed::Worker.delay_jobs = false
            
            click_button submit, match: :first
            # for debugging:
            #p page.html.gsub(/[\n\t]/, '')
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
            page.html.gsub(/[\n\t]/, '').should match(/provisioning success/)                    
          end
          
          it "should create a provisioning task" do
            expect { click_button submit, match: :first }.to change(Provisioning, :count).by(1)         
          end
          
          it "should create a provisioning task (2nd 'Save' button)" do
            expect { first('.index').click_button submit, match: :first }.to change(Provisioning, :count).by(1)         
          end
          
          #it "should create a provisioning task with action='action=Add Customer' and 'customerName=ExampleCustomer'" do
          it "should create a provisioning task with action='action=Add #{obj}' and 'customerName=#{$customerName} etc." do
            click_button submit, match: :first
            createdProvisioningTask = Provisioning.find(Provisioning.last)
            createdProvisioningTask.action.should match(/action=Add #{obj}/)
            case obj
              when /Customer/
                createdProvisioningTask.action.should match(/customerName=#{$customerName}/)
              when /Site/
                createdProvisioningTask.action.should match(/customerName=#{$customerName}/)
                createdProvisioningTask.action.should match(/SiteName=ExampleSite/)
                #createdProvisioningTask.action.should match(/SC=99821/)
                createdProvisioningTask.action.should match(/CC=49/)
                createdProvisioningTask.action.should match(/AC=99/)
                createdProvisioningTask.action.should match(/LOC=7007/)
                createdProvisioningTask.action.should match(/XLen=5/)
                createdProvisioningTask.action.should match(/EndpointDefaultHomeDnXtension=10000/)
              when /User/
                createdProvisioningTask.action.should match(/customerName=#{$customerName}/)
                createdProvisioningTask.action.should match(/SiteName=ExampleSite/)
                createdProvisioningTask.action.should match(/X=30800/)
                createdProvisioningTask.action.should match(/givenName=Oliver/)
                createdProvisioningTask.action.should match(/familyName=Veits/)
                createdProvisioningTask.action.should match(/assignedEmail=oliver.veits@company.com/)
                createdProvisioningTask.action.should match(/imAddress=oliver.veits@company.com/)
            end
          end
          
          #it "should create a provisioning task that finishes successfully or throws an Error 'Customer exists already'" do
          it "should create a provisioning task that finishes successfully or it should throw an Error 'exists already'" do
            Delayed::Worker.delay_jobs = false
            click_button submit, match: :first
            # find last Add Provisioning task
            createdProvisioningTask = Provisioning.where('action LIKE ?', "%action=Add #{obj}%").last
            begin
              createdProvisioningTask.status.should match(/finished successfully/)
            rescue
                createdProvisioningTask.status.should match(/#{obj} exists already/) if obj == "Customer"
                createdProvisioningTask.status.should match(/exists already/) if obj == "Site"
                createdProvisioningTask.status.should match(/phone number is in use already/) if obj == "User"
            end
          end  

          it "should save an #{obj} with status 'waiting for provisioning'" do
            Delayed::Worker.delay_jobs = true
            click_button submit, match: :first
            expect(page.html.gsub(/[\n\t]/, '')).to match(/waiting for provisioning/)
          end


        end # describe "Provisioning" do
      end # describe "with valid information" do 

      describe "that exists already on target system" do
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

        it "should create a #{obj} with status 'provisioning success: was already provisioned'" do
          Delayed::Worker.delay_jobs = false
          click_button submit, match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/was already provisioned/)
        end

	if obj == "Site"
          it "should update the #{obj} in the DB according to the data found in the target system" do
            Delayed::Worker.delay_jobs = false
            click_button submit, match: :first
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
        
	it "should update the status of #{obj} 'waiting for deletion'" do
          Delayed::Worker.delay_jobs = true
      #p page.html.gsub(/[\n\t]/, '')
      #expect(page.html.gsub(/[\n\t]/, '')).to match(/Delete Site/)
          click_link submit, match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/waiting for de-provisioning/)
        end

	it "should update the status of #{obj} 'waiting for deletion' also for objects that had import errors" do
          myObjects = myProvisioningobject(obj).where(name: $customerName ) if obj == "Customer"
          myObjects = myProvisioningobject(obj).where(name: "Example#{obj}" ) unless obj == "User" || obj == "Customer"
          myObjects = myProvisioningobject(obj).where(Extension: "30800" ) if obj == "User"
	  myObjects[0].update_attributes!(:status => "provisioning failed (import errors)")
          Delayed::Worker.delay_jobs = true
      #p page.html.gsub(/[\n\t]/, '')
      #expect(page.html.gsub(/[\n\t]/, '')).to match(/Delete Site/)
          click_link submit, match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/waiting for de-provisioning/)
        end

        # TODO: add destroy use cases
        #       1) De-Provisioning of customer
        #       2) Deletion of customer from database
        it "should de-provision a #{obj} with status 'deletion success'" do
          # synchronous operation, so we will get deterministic test results:         
          Delayed::Worker.delay_jobs = false
          
          click_link submit, match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/deletion success/) #have_selector('h2', text: 'Customers')
          
          # /customers/<id> should show deletion success
          myObjects = myProvisioningobject(obj).where(name: $customerName ) if obj == "Customer"
          myObjects = myProvisioningobject(obj).where(name: "Example#{obj}" ) unless obj == "User" || obj == "Customer"
          myObjects = myProvisioningobject(obj).where(Extension: "30800" ) if obj == "User"
          #p customers
          visit provisioningobject_path(myObjects[0])
          # for debugging:
          #p page.html.gsub(/[\n\t]/, '')
          page.html.gsub(/[\n\t]/, '').should match(/deletion success/)      
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
            click_link "Delete #{obj}"
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
end # Array["Customer", "Site", "User"].each do |obj|

describe "Customer can be de-provisioned, even if a manually added site is present" do
  # TODO:
  # create Customer, create site, delete site from DB only, so it is still on the target system.
  # it ...
  #   destroyCustomer
  # should be successful, because before deleting, all sites should be synchronized back from the target systems to the PE
end

#describe "Site" do
  #its "SiteCode should be unique for the target" do
    #expect  
