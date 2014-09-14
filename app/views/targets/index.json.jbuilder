json.array!(@targets) do |target|
  json.extract! target, :id, :name, :configuration
  json.url target_url(target, format: :json)
end
