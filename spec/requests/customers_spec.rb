require 'spec_helper'

describe "Customers" do
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
    
  end
  
  describe "new" do
    before { visit new_customer_path }
    
    it "should have the header 'New Customer'" do
      expect(page).to have_selector('h2', text: 'New Customer')
    end
    
    its "Cancel button in the left menue leads to the Customers index page" do
      #first(:link, "Cancel").click
      click_link("Cancel", match: :first)
      #click_link "Cancel"
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
          #Preparation: create target in test database:
          Target.create(name: 'TestTarget', configuration: 'a=b')
          visit new_customer_path # for refreshing after creating the target
          fill_in "Name",         with: "ExampleCustomer"         
          
          # Expected drop down in HTML page:
          #<select id="customer_target_id" name="customer[target_id]">
          #<option value="">Select a Target</option>
          #<option value="2">TestTarget</option></select>

          # OV: works, if target ID=2. However, we cannot know, which ID the TestTarget will get (depends on history of database)
          #find_by_id('customer_target_id').find("option[value='2']").select_option #find("option[value='1']").select_option
          # better:
          select "TestTarget", :from => "customer[target_id]"
        end
        
        it "should create a customer" do
          expect { click_button submit, match: :first }.to change(Customer, :count).by(1)         
        end
        
        it "should create a provisioning task" do
          expect { click_button submit, match: :first }.to change(Provisioning, :count).by(1)         
        end
        
        it "should create a provisioning task with action='action=Add Customer' and 'customerName=ExampleCustomer'" do
          click_button submit, match: :first
          createdProvisioningTask = Provisioning.find(Provisioning.count)
          createdProvisioningTask.action.should match(/action=Add Customer/)
          createdProvisioningTask.action.should match(/customerName=ExampleCustomer/)
        end
        
        
        it "should create a customer on second 'Save' button" do
          expect { first('.index').click_button submit, match: :first }.to change(Customer, :count).by(1)
        end
        
        it "should create a provisioning task (2nd save button)" do
          expect { first('.index').click_button submit, match: :first }.to change(Provisioning, :count).by(1)         
        end
      end
      
    end
    
  end
end
