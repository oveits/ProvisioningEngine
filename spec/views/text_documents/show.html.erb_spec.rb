require 'spec_helper'

describe "text_documents/show" do
  before(:each) do
    @text_document = assign(:text_document, stub_model(TextDocument,
      :identifierhash => "MyText",
      :content => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/MyText/)
    rendered.should match(/MyText/)
  end
end
