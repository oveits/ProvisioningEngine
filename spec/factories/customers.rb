# spec/factories/customers.rb
FactoryGirl.define do
  factory :customer do |f|
    f.name "nonProvisionedCust"
    f.target_id 2
  end
end
