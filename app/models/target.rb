class Validate_Variable_Value_Pairs < ActiveModel::Validator
# TODO: DRYing this code: this is a duplicate from app/model/provisioning.rb
  def validate(record)


    if record.configuration.nil? || record.configuration == ""
      record.errors[:configuration] << "must be of the format \"variable1=value1,variable2=value2, ... (linebreaks instead of ',' are allowed)\""
    else

      array = record.configuration.split(/,/).map(&:strip) unless record.configuration.nil?

      #postData = {}

      while array[0]
        variableValuePairArray = array.shift.split(/=/).map(&:strip)
        if variableValuePairArray.length.to_s[/^1$|^2$/]
          #postData[variableValuePairArray[0]] = variableValuePairArray[1]
        else
          record.errors[:configuration] << "must be of the format \"variable1=value1,variable2=value2, ... (linebreaks instead of ',' are allowed)\""
          #raise 'The POST data must be of the format "variable1=value1,variable2=value2, ..."'
        end
      end # while
    end # if
  end # def
end


class Target < Provisioningobject #ActiveRecord::Base

  def target
    self
  end

  def parentClass
    nil
  end

  def self.parentClass
    nil
  end

  def parent
    nil
  end
  
  def parentSym
    nil
  end
  
  def self.parentSym
    nil
  end
  
  def self.provisioningAction(method)
    nil
  end
  
  def provisioningAction(method)

    case method
      when :create
        #"action=PrepareSystem"
     # for now, since it does not work correctly and is not fully tested:
        nil
      else
        raise "Unsupported provisioning method"
    end

  end
  
  def self.childClass
    Customer
  end
  
  def childClass
    Customer
  end

  def children
    Customer.where(target_id: id).order(:name)
  end

  def provision(method, async=true)
    super
  end
  
  def recursiveConfiguration
    configuration
  end

  #belongs_to :customer

  #has_many :customers
  # replaced by:
  # we need to destroy all customers, if a target is destroyed (otherwise we get a "target does not exist" error in the site/new and user/new view):
  has_many :customers, dependent: :destroy

  validates :name, presence: true, uniqueness: true
# TODO: does not work yet for valid target configurations. Therefore commented out.
  #validates_with Validate_Variable_Value_Pairs
end
