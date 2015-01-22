#json.extract! @site, :id, :name, :customer_id, :created_at, :updated_at, :status
# replaced by (see http://stackoverflow.com/questions/23027644/how-to-extract-all-attributes-with-rails-jbuilder)
json.merge! @site.attributes
