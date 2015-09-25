FROM rails

RUN apt-get update 

# if you need vi and less for easier troubleshooting later on:
RUN apt-get install -y vim; apt-get install -y less

ADD . /ProvisioningEngine

# Define working directory.
WORKDIR /ProvisioningEngine

RUN bundle install

EXPOSE 3000

CMD ["rails", "s"]
