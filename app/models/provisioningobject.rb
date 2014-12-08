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
    if /provisioning success/.match(status)
      true
    else
      false
    end
  end
  
  def provision(method, async=true)
#    provisionNew(provisioningAction(method), async)
#  end
#  
#  def provisionNew(inputBody, async)
    inputBody = provisioningAction(method)

    @provisioningobject = self
#abort @provisioningobject.inspect
    # e.g. inputBody = "action = Add Customer, customerName=#{name}" 
    
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
         @provisioning.deliverasynchronously
       else
#abort @provisioning.inspect
         @provisioning.deliver
       end
       # success
       #return 0
    else
      @provisioning.errors.full_messages.each do |message|
        abort 'provisioning error: ' + message.to_s
      end
    end 
  end # def
  
end


