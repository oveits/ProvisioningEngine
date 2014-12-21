# spec/factories/customers.rb
FactoryGirl.define do
  factory :customer do |f|
    f.name "nonProvisionedCust"
    f.language Customer::LANGUAGE_ENGLISH_US
    f.target_id 2
  end
end
