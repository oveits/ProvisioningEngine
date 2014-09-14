json.array!(@customers) do |customer|
  #json.extract! customer, :id, :name
  # replaced by (see http://stackoverflow.com/questions/23027644/how-to-extract-all-attributes-with-rails-jbuilder)
  json.merge! customer.attributes 
  json.url customer_url(customer, format: :json)
end
