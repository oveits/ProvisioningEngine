class Provisioningobject < ActiveRecord::Base
  self.abstract_class = true # makes the model abstract

  PROVISIONINGTIME = [PROVISIONINGTIME_IMMEDIATE = 'immediate', PROVISIONINGTIME_AD_HOC = 'ad-hoc'] # PROVISIONINGTIME_SCHEDULED = 'scheduled'

  # allow transient attribute (i.e. an attribute that is not mapped to a column in the database)
  attr_accessor :provisioningtime
 
  after_initialize :init

  def init
    self.status ||= 'not provisioned'
  end

  def provisioningtime
    @provisioningtime.nil? ? PROVISIONINGTIME_IMMEDIATE : @provisioningtime
  end
  
  def new
  end
  
  def path
    return "/#{provisioningobject.class.to_s.downcase}/#{provisioningobject.id}"
  end
  
  def activeJob?
    # will return true, if the object has an active job
    
    #TODO: needs to return true also recursively, if one of the children has an active job
    
    object_sym = self.class.to_s.downcase.to_sym
    
    @provisionings = Provisioning.where(object_sym => self)
    #abort @provisionings.inspect
    
    # search for active jobs:
    @provisionings.each do |provisioning|    
      return true if provisioning.activeJob?
    end
    
    # else return false:
    return false
  end
  
  def provisioned?
    case status
      when /was already de-provisioned/
        false
      when /provisioning success|failed \(import errors\)|deletion failed|waiting for deletion/
        true
      else
        false
    end
  end
  
  def provision(method, async=true)

    # update the status of the object; throws an exception, if the object cannot be saved.
    case method
      when :create
        methodNoun = "provisioning"
        #return false if activeJob?
        #return false if provisioned?
      when :destroy
        methodNoun = "de-provisioning"
        #return false if activeJob?
        #return false if !provisioned?
      when :read
        methodNoun = "reading"
      else
        abort "provision(method=#{method}, async=#{async}): Unknown method"
    end
    # this will fail for old objects that do not yet obey to the validations:
    #update_attributes!(status: "waiting for #{methodNoun}")
    # it is better to update the status, even if the other validations might fail:
    update_attribute(:status, "waiting for #{methodNoun}") unless method == :read

    # set body to be sent to the ProvisioningEngine target: e.g. inputBody = "action = Add Customer, customerName=#{name}" 
    inputBody = provisioningAction(method)

    @provisioningobject = self
    
    unless target.nil?
      actionAppend = target.configuration.gsub(/\r/, '')
      actionAppend = actionAppend.gsub(/^[\s]*\n/,'') # ignore empty lines
      actionAppend = actionAppend.gsub(/\n/, ', ')
      actionAppend = actionAppend.gsub(/,[\s]*\Z/, '')# remove trailing commas
    end
    
    # recursive deletion of children (skipped in test mode):
    if inputBody.include?("Delete") && !inputBody.include?("testMode") 
      #@sites = Site.where(customer: id)
      children.each do |child|
        child.provision(:destroy, async)
      end unless children.nil?
    end

    # recursive creation of parents for Add (:create) functions
    if inputBody.include?("Add ") && !inputBody.include?("testMode")
       self.parent.provision(:create, async) unless self.parent.nil?
    end
    
    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?

    object_sym = self.class.to_s.downcase.to_sym
    
    @provisioning = Provisioning.new(action: inputBody, object_sym => @provisioningobject)

    if @provisioning.save
       if async == true
         returnvalue = @provisioning.deliverasynchronously
       else
         returnvalue = @provisioning.deliver
       end
    else
      @provisioning.errors.full_messages.each do |message|
        abort 'provisioning error: ' + message.to_s
      end
    end 
    returnvalue
  end # def provision(method, async=true)

def dropdownlist(type)
  if type == :countrycode
    COUNTRYCODES
  end 
end 

    # see http://rails-bestpractices.com/posts/708-clever-enums-in-rails
    LANGUAGES = [LANGUAGE_ENGLISH_US = 'englishUS', LANGUAGE_ENGLISH_GB = 'englishGB', LANGUAGE_GERMAN = 'german'] # spanish, frensh, italian, portuguesePT, portugueseBR, dutch, russian, turkish
    COUNTRYCODES = [COUNTRYCODE_US = '1', COUNTRYCODE_GB = '44', COUNTRYCODE_DE = '49']
    LIST = {}
    LIST[:countrycode] = COUNTRYCODES
    
    # does not work yet:
    validates :provisioningtime, inclusion: {in: PROVISIONINGTIME}
end


