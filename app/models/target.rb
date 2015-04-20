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
          #abort 'The POST data must be of the format "variable1=value1,variable2=value2, ..."'
        end
      end # while
    end # if
  end # def
end

class Target < Provisioningobject #ActiveRecord::Base

  def parent
    nil
  end
  
  def parentSym
    nil
  end
  
  def self.parentSym
    nil
  end
  
  def provisioningAction(method)
    nil
  end
  
  def self.childClass
    Customer
  end
  
  def childClass
    Customer
  end

  def provision(method, async=true)
    # overrides the provision method found in app/models/provisioningobject.rb
    # since provisioning is not supported and :read will never be supported, we need a specific handling for targets

# not yet supported:
    return false
#######################################
#    @provisioningobject = self
#
#    # update the status of the object; throws an exception, if the object cannot be saved.
#    case method
#      when :create
#        methodNoun = "provisioning"
#        abort "provisioning not supported yet for targets"
#        #return false if activeJob?
#        #return false if provisioned?
#      when :destroy
#        methodNoun = "de-provisioning"
#        abort "provisioning not supported yet for targets"
#        #return false if activeJob?
#        #return false if !provisioned?
#      when :read
#        methodNoun = "reading"
#        return "<Result><Target>#{name}</Target></Result>"
#      else
#        abort "provision(method=#{method}, async=#{async}): Unknown method"
#    end
  end
  
  def recursiveConfiguration
    configuration
  end

  #belongs_to :customer
  has_many :customers
  validates :name, presence: true, uniqueness: true
# TODO: does not work yet for valid target configurations. Therefore commented out.
  #validates_with Validate_Variable_Value_Pairs
end
