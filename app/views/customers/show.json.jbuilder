#json.extract! @customer, :id, :name, :created_at, :updated_at
# replaced by (see http://stackoverflow.com/questions/23027644/how-to-extract-all-attributes-with-rails-jbuilder)
json.merge! @customer.attributes
