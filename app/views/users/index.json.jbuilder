json.array!(@users) do |user|
  json.extract! user, :id, :name, :site_id, :extension, :givenname, :familyname, :email
  json.url user_url(user, format: :json)
end
