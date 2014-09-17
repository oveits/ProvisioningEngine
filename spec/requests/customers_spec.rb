require 'spec_helper'

describe "Customers" do
  describe "index" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get customers_path
      response.status.should be(200)
    end
    
    it "should have the content 'Customers'" do
      visit customers_path
      expect(page).to have_content('Customers')
    end
  end
end
