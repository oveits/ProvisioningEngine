require 'spec_helper'

describe "text_documents/edit" do
  before(:each) do
    @text_document = assign(:text_document, stub_model(TextDocument,
      :identifierhash => "MyText",
      :content => "MyText"
    ))
  end

  it "renders the edit text_document form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", text_document_path(@text_document), "post" do
      assert_select "textarea#text_document_identifierhash[name=?]", "text_document[identifierhash]"
      assert_select "textarea#text_document_content[name=?]", "text_document[content]"
    end
  end
end
