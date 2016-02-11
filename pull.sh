#!/bin/sh
git pull
bundle install
rake db:migrate RAILS_ENV=test
rake db:migrate RAILS_ENV=development
