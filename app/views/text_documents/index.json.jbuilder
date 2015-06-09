json.array!(@text_documents) do |text_document|
  json.extract! text_document, :id, :identifierhash, :content
  json.url text_document_url(text_document, format: :json)
end
