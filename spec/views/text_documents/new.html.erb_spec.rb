require 'spec_helper'

describe "text_documents/new" do
  before(:each) do
    assign(:text_document, stub_model(TextDocument,
      :identifierhash => "MyText",
      :content => "MyText"
    ).as_new_record)
  end

  it "renders new text_document form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", text_documents_path, "post" do
      assert_select "textarea#text_document_identifierhash[name=?]", "text_document[identifierhash]"
      assert_select "textarea#text_document_content[name=?]", "text_document[content]"
    end
  end
end
