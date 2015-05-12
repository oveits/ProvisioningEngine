set HTTP_PROXY=
set http_proxy=

rem for the case the database is not yet migrated:
start bundle exec rake db:migrate RAILS_ENV=test

rem always same order, with description for documentation:
bundle exec rspec -f d spec/requests/provisioningobjects_spec.rb %*

rem randomized, but without description:
rem bundle exec rspec spec/requests/provisioningobjects_spec.rb %*
