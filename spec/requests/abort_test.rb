# spec/controllers/admin/system_settings_controller_spec.rb
require 'spec_helper'
include Devise::TestHelpers

RSpec.configure do |config|
  #config.fail_fast = true
  config.include Rails.application.routes.url_helpers

  config.after(:suite) do
    examples = RSpec.world.filtered_examples.values.flatten
    if examples.none?(&:exception)
      p "no exception recorded in config.after(:suite)"
    else
      p "exception recorded in config.after(:suite)"
    end
  end
end

def aborting_method
  abort "this is a method that raises an exception"
end

def method_raising_runtime_error
  raise "this method raises a standard runtime error"
end

#describe "Wrapper" do
#it "should fail" do
describe "Abort" do
  describe "explicitly in before script" do
    before {
      abort "this is an abort in the before script"
    }
    it "hides a failure" do
      expect(1).to eq (2)
    end
  end 

  describe "implicitly called in before script" do
    before {
      aborting_method
    }
    it "hides a failure" do
      expect(1).to eq (2)
    end
  end 
  
  describe "in expect block" do
    it "raises SystemExit exception, if abort explicitly used" do
      expect { abort "should fail on abort" }.to raise_exception(SystemExit)
    end
    it "raises SystemExit exception, if abort created by called method" do
      expect { aborting_method }.to raise_exception(SystemExit)
    end
    it "raises SystemExit error, if abort explicitly used" do
      expect { abort "should fail on abort" }.to raise_error(SystemExit)
    end
    it "raises SystemExit error, if abort created by called method" do
      expect { aborting_method }.to raise_error(SystemExit)
    end
  end

  describe "explicitly raised anywhere in it block" do
    it "is ignored and leads to immediate stop of the test suite" do
      abort "bla"
      expect(1).to eq (2)
    end
  end

  describe "implicitly raised anywhere in it block" do
    it "is ignored and leads to immediate stop of the test suite" do
      aborting_method
      expect(1).to eq (2)
    end
  end
end

describe "Raise" do
  it "expect(1).to eq(2) raises ExpectationNotMetError" do
    expect { expect(1).to eq(2) }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  describe "explicitly in before script" do
    before {
      raise "this is raise RuntimeError in the before script"
    }
    it "fails with RuntimeError" do
      expect(1).to eq (2)
    end
  end 

  describe "implicitly called in before script" do
    before {
      method_raising_runtime_error
    }
    it "fails with RuntimeError" do
      expect(1).to eq (2)
    end
  end 

  describe "in expect block" do
    it "raises RuntimeError exception, if abort explicitly used" do
      expect { raise "should fail on raise" }.to raise_exception(RuntimeError)
    end
    it "raises RuntimeError exception, if raised in called method" do
      expect { method_raising_runtime_error }.to raise_exception(RuntimeError)
    end
    it "raises RuntimeError error, if raise explicitly used" do
      expect { raise "should fail on abort" }.to raise_error(RuntimeError)
    end
    it "raises RuntimeError error, if raised in called method" do
      expect { method_raising_runtime_error }.to raise_error(RuntimeError)
    end
  end

  describe "explicitly raised anywhere in it block" do
    it "leads to failed tests" do
      raise "raised RuntimeError"
      expect(1).to eq (2)
    end
  end

  describe "implicitly raised anywhere in it block" do
    it "leads to failed tests" do
      method_raising_runtime_error
      expect(1).to eq (2)
    end
  end
end
#end
#end

