require 'spec_helper'

def createCustomer(customerName = "ExampleCustomer")      
  # add and provision customer "ExampleCustomer with target = TestTarget"
  fillFormForNewCustomer(customerName)
  click_button 'Save', match: :first 
end

def fillFormForNewCustomer(customerName = "ExampleCustomer")
  # create target, and fill out the form on /customers/new
  Target.create(name: 'TestTarget', configuration: 'a=b')
  visit new_customer_path # for refreshing after creating the target
  fill_in "Name",         with: customerName        
  select "TestTarget", :from => "customer[target_id]"
  
  # Note: select "TestTarget" selects the <option value=_whatever_>TestTarget</option> in the following select part of the HTML page:
  # Expected drop down in HTML page:
          #    <select id="customer_target_id" name="customer[target_id]">
          #    <option value="">Select a Target</option>
          #    <option value="2">TestTarget</option></select>
end

describe "Customers" do
  #before { debugger }
  describe "index" do
    before { visit customers_path }   
    #subject { page }
    
    it "should have the header 'Customers'" do
      expect(page).to have_selector('h2', text: 'Customers')
    end
    
    it "should have link to 'New Customer'" do
      expect(page).to have_selector('a', text: 'New Customer')
    end
    
    its "link to 'New Customer' leads to correct page" do
      click_link "New Customer"
      expect(page).to have_selector('h2', text: 'New Customer')    
    end
    
  end # of describe "index" do
  
  describe "New Customer" do
    before { visit new_customer_path }
    
    it "should have the header 'New Customer'" do
      expect(page).to have_selector('h2', text: 'New Customer')
    end
    
    its "Cancel button in the left menue leads to the Customers index page" do
      click_link("Cancel", match: :first)
      expect(page).to have_selector('h2', text: 'Customers')    
    end
    
    its "Cancel button in the web form leads to the Customers index page" do
      #find html tag with class=index. Within this tag, find and click link 'Cancel' 
      first('.index').click_link('Cancel')
      expect(page).to have_selector('h2', text: 'Customers')    
    end
    
    describe "Create Customer" do
      before { visit new_customer_path }
      let(:submit) { "Save" }
  
      describe "with invalid information" do
        it "should not create a customer" do
          expect { click_button submit, match: :first }.not_to change(Customer, :count)
        end
        
        it "should not create a customer on second 'Save' button" do
          expect { first('.index').click_button submit, match: :first }.not_to change(Customer, :count)
        end
      end
      
      describe "with valid information" do
        # does not work yet (is just ignored):
        #let(:target) { FactoryGirls.create(:target) }
        before do
          fillFormForNewCustomer
        end
        
        it "should create a customer" do
          expect { click_button submit, match: :first }.to change(Customer, :count).by(1)       
        end
        
        it "should create a customer (2nd 'Save' button)" do
          expect { first('.index').click_button submit, match: :first }.to change(Customer, :count).by(1)
        end
        
        it "should create a customer with status 'provisioning success'" do
          # synchronous operation, so we will get deterministic test results:         
          Delayed::Worker.delay_jobs = false
          
          # /customers/index should show provisioning success
          click_button submit, match: :first
          expect(page.html.gsub(/[\n\t]/, '')).to match(/provisioning success/) #have_selector('h2', text: 'Customers')
          
          # /customers/<id> should show provisioning success
          visit customer_path(Customer.count)
          p page.html.gsub(/[\n\t]/, '')
          page.html.gsub(/[\n\t]/, '').should match(/provisioning success/)        
        end
        
        
        it "should create a provisioning task" do
          expect { click_button submit, match: :first }.to change(Provisioning, :count).by(1)         
        end
        
        it "should create a provisioning task (2nd 'Save' button)" do
          expect { first('.index').click_button submit, match: :first }.to change(Provisioning, :count).by(1)         
        end
        
        it "should create a provisioning task with action='action=Add Customer' and 'customerName=ExampleCustomer'" do
          click_button submit, match: :first
          createdProvisioningTask = Provisioning.find(Provisioning.count)
          createdProvisioningTask.action.should match(/action=Add Customer/)
          createdProvisioningTask.action.should match(/customerName=ExampleCustomer/)
        end
        
        it "should create a provisioning task that finishes successfully or throws an Error 'Customer exists already'" do
          Delayed::Worker.delay_jobs = false
          click_button submit, match: :first
          createdProvisioningTask = Provisioning.find(Provisioning.count)
          begin
            createdProvisioningTask.status.should match(/finished successfully/)
          rescue
            createdProvisioningTask.status.should match(/Customer exists already/)          
          end
          
        end  
        
      end # of describe "with valid information" do
      
    end # of describe "Create Customer" do
    
    describe "De-Provision Customer" do
      before {
        # synchronous hancdling to make test results more deterministic
        Delayed::Worker.delay_jobs = false
        createCustomer
        Delayed::Worker.delay_jobs = true             
        visit customer_path(Customer.count)
        #p page.html.gsub(/[\n\t]/, '')
       
       }
         
      let(:submit) { "Delete Customer" }
      let(:submit2) { "Destroy" }
      
      # TODO: add destroy use cases
        # De-Provisioning of customer
        # Deletion of customer from database
      it "should delete a customer with status 'deletion success'" do
        # synchronous operation, so we will get deterministic test results:         
        Delayed::Worker.delay_jobs = false
        
        click_link submit, match: :first
        expect(page.html.gsub(/[\n\t]/, '')).to match(/deletion success/) #have_selector('h2', text: 'Customers')
        
        # /customers/<id> should show provisioning success
        visit customer_path(Customer.count)
        p page.html.gsub(/[\n\t]/, '')
        page.html.gsub(/[\n\t]/, '').should match(/deletion success/)        
      end
    end
    
    describe "Delete Customer from database" do
      
      before {
        # setting Delayed::Worker.delay_jobs = true causes the provisioning task not to be executed (assumption: rake jobs:work task is not started for the test enviroment)
        Delayed::Worker.delay_jobs = true
        createCustomer("nonProvisionedCust")        
        visit customer_path(Customer.count)
        #p page.html.gsub(/[\n\t]/, '')       
       }
         
      let(:submit) { "Delete Customer" }
      let(:submit2) { "Destroy" }
      
      it "should remove a customer from the database, if not found on the target system" do
        Delayed::Worker.delay_jobs = false # to make sure the target system is checked for the customer       
        expect { click_link submit, match: :first }.to change(Customer, :count).by(-1)
      
      end
      
    end # of describe "Destroy Customer" do
    
  end # describe "index" do
end # describe "Customers" do
