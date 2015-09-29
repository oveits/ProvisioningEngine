FROM rails

# update the operating system:
RUN apt-get update 

# if you need "vi" and "less" for easier troubleshooting later on:
RUN apt-get install -y vim; apt-get install -y less

# copy the ProvisioningEngine app to the container:
ADD . /ProvisioningEngine

# Define working directory:
WORKDIR /ProvisioningEngine

# Install the Rails Gems and prepare the database:
RUN bundle install; bundle exec rake db:migrate RAILS_ENV=development

# expose tcp port 80
EXPOSE 80

# default command: run the web server on port 80:
CMD ["rails", "server", "-p", "80"]
