require 'spec_helper'

describe "text_documents/index" do
  before(:each) do
    assign(:text_documents, [
      stub_model(TextDocument,
        :identifierhash => "MyText",
        :content => "MyText"
      ),
      stub_model(TextDocument,
        :identifierhash => "MyText",
        :content => "MyText"
      )
    ])
  end

  it "renders a list of text_documents" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
