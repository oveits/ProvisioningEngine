class Provisioningobject < ActiveRecord::Base
  self.abstract_class = true # makes the model abstract
  
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
      when /provisioning success|failed \(import errors\)|deletion failed/
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
      when :destroy
        methodNoun = "de-provisioning"
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
#abort @provisioningobject.inspect
    
    unless target.nil?
      actionAppend = target.configuration.gsub(/\r/, '')
      actionAppend = actionAppend.gsub(/^[\s]*\n/,'') # ignore empty lines
      actionAppend = actionAppend.gsub(/\n/, ', ')
      actionAppend = actionAppend.gsub(/,[\s]*\Z/, '')# remove trailing commas
#abort actionAppend      
    end
    
    # recursive deletion of children (skipped in test mode):
#abort self.id.inspect
#abort Site.where(customer: self.id).inspect
#abort children.inspect
#abort "I do not know yet how to find the children..."
    if inputBody.include?("Delete") && !inputBody.include?("testMode") 
      #@sites = Site.where(customer: id)
      children.each do |child|
#abort child.inspect
        #child.de_provision(async)
        child.provision(:destroy, async)
        #inputBodySite = "action=Delete Site, customerName=#{@provisioningobject.name}, SiteName=#{site.name}"
        #inputBodySite = inputBodySite + ', ' + actionAppend unless actionAppend.nil?
        #site.provision(inputBodySite, async)
      end unless children.nil?
    end
    
    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?

#abort inputBody.inspect
    object_sym = self.class.to_s.downcase.to_sym
    
    @provisioning = Provisioning.new(action: inputBody, object_sym => @provisioningobject)

    #@provisioning = Provisioning.new(action: inputBody, customer: @provisioningobject)
    
    if @provisioning.save
       #@provisioning.createdelayedjob
       #@provisioning.deliver
       if async == true
         returnvalue = @provisioning.deliverasynchronously
       else
#abort @provisioning.inspect
         returnvalue = @provisioning.deliver
       end
       # success
       #return 0
    else
      @provisioning.errors.full_messages.each do |message|
        abort 'provisioning error: ' + message.to_s
      end
    end 
    returnvalue
  end # def

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

end


