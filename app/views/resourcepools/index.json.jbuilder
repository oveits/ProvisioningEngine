json.array!(@resourcepools) do |resourcepool|
  json.extract! resourcepool, :id, :name, :resource
  json.url resourcepool_url(resourcepool, format: :json)
end
