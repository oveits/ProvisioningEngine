json.array!(@provisionings) do |provisioning|
  #json.extract! provisioning, :id, :action
  # replaced by (see http://stackoverflow.com/questions/23027644/how-to-extract-all-attributes-with-rails-jbuilder)
  json.merge! provisioning.attributes
  json.url provisioning_url(provisioning, format: :json)
end
