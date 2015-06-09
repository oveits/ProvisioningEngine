require "spec_helper"

describe TextDocumentsController do
  describe "routing" do

    it "routes to #index" do
      get("/text_documents").should route_to("text_documents#index")
    end

    it "routes to #new" do
      get("/text_documents/new").should route_to("text_documents#new")
    end

    it "routes to #show" do
      get("/text_documents/1").should route_to("text_documents#show", :id => "1")
    end

    it "routes to #edit" do
      get("/text_documents/1/edit").should route_to("text_documents#edit", :id => "1")
    end

    it "routes to #create" do
      post("/text_documents").should route_to("text_documents#create")
    end

    it "routes to #update" do
      put("/text_documents/1").should route_to("text_documents#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/text_documents/1").should route_to("text_documents#destroy", :id => "1")
    end

  end
end
