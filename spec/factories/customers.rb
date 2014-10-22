# spec/factories/customers.rb
FactoryGirl.define do
  factory :customer do |f|
    f.name "ExampleCustomer"
    f.target_id 1
  end
end
