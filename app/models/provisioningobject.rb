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
  
  def path(prefix)
    abort "method path() in app/models/provisioningobject.rb is broken. Fix before use. E.g. see app/views/shared/_helpers.html.erb->provisioningobject_path() for a correctly working example"
    prefixPrepend = "#{prefix}_" unless prefix.nil? 
    #return send("#{prefix}#{myobject(thisobject.class.to_s)}_path", thisobject.id)
    #abort send("#{prefix}#{self.class.name.downcase}_path").inspect if prefix == 'deprovision_'
    #abort self.id.inspect if prefix == 'deprovision_'
    #return send("#{prefix}#{self.class.name.downcase}_path", self.id)

    # does not work, error message: 
    #return send("#{prefixPrepend}#{self.class.name.downcase}_path", self.id)

    # seems to work, but is not flexible enough (e.g. prefix 'dev/' is missing on the development web portal):
    if ENV["WEBPORTAL_BASEURL"] == "false" || ENV["WEBPORTAL_BASEURL"].nil?
      baseURL = '/'
    else
      baseURL = ENV["WEBPORTAL_BASEURL"] + '/'
    end

    if prefix == ''
      return "#{baseURL}#{self.class.to_s.downcase.pluralize}/#{self.id}" if prefix.nil?
    else
      return "#{baseURL}#{self.class.to_s.downcase.pluralize}/#{self.id}/#{prefix}"
    end
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
  
  def synchronize(async=true, recursive=true)
#abort async.inspect
    #return false if /waiting|progress/.match(status)
    #updateDB = UpdateDB.new
    if async

      # the next line had lead to a severe bug with error message "SQLite3::BusyException: database is locked", if the customer validates_format_of name was wrong (:name, :with => /\A[A-Z,a-z,0-9,_]{0,100}+\Z/ instead of :name, :with => /\A[A-Z,a-z,0-9,_]{0,100}\Z/)
      #update_attributes(:status => 'synchronization in progress')
      # works fine in any case, since the validations are skipped:
      update_attribute(:status, 'synchronization in progress')

      #returnBody = updateDB.delay.perform(self)
      # or:
      returnBody = delay.synchronizeSynchronously(recursive)
    else
      #returnBody = updateDB.perform(self)
      # or:
      returnBody = synchronizeSynchronously(recursive)
    end
  end
  
  def self.synchronizeAll(parents = nil, async=true, recursive=false)
    # 
    # synchronizes all objects of the specific class to the local database
    # with recursive == true, also the child classes are synchronized
    # 
    # TODO: create rspec tests for recursive synchronizeAll, if not already present and test with recursive = true (also see controller)
    
    abort "recursive mode of synchronizeAll is not yet supported" if recursive

    parents ||= parentClass.all

    # find target systems involved:
    targetsArray = parents.map {|i| i.target}.uniq
		#abort targetsArray.inspect
		#abort async.inspect

    # for each target involved, perform a synchronization task (in the background for async==true):
    targetsArray.each do |target_i|

      # For each target, find all parents, which are in the parents list and are on this target
      if parents.last.class == Target
        parents_of_this_target = targetsArray 
      else
        parents_of_this_target = parents.select{ |i| i.target.id == target_i.id}
      end
		#abort parents_of_this_target.inspect

      # perform synchronizeAllSynchronously(parents_of_this_target, recursive)
      if async
        delay.synchronizeAllSynchronously(parents_of_this_target, recursive)
      else # if async
        # there is a problem, if one of the parents is not reachable (abort). In order to synchronize other targets in this case, a rescue is needed.
        begin
          synchronizeAllSynchronously(parents_of_this_target, recursive)
        rescue Exception
          returnBody = "There were errors with synchronizeAllSynchronously"
        end
      end # if async

    end # targetsArray.each do |target_i|
  end # def self.synchronizeAll(parents = nil, async=true, recursive=false)

  def synchronizeSynchronously(recursive=true)
    #
    # synchronize a single object in the local database with the information found on the target
    #
    # TODO: replace dummyChild by synchronizeAll

    updateDB = UpdateDB.new
    responseBody = updateDB.perform(self)
            #abort "model: synchronize" + self.inspect
    if recursive && responseBody.is_a?(String) && responseBody[/ERROR.*$/].nil? && !childClass.nil?
      # TODO: read children from target, create children in DB, if not present yet, and perform a child.synchronizeSynchronously(recursive)
      #dummyChild = childClass.new(customer: self) #self.class.name.downcase.to_sym => self) # needed in order to access the provision method of the child class

      dummyChild = childClass.new(self.class.name.downcase.to_sym => self) # needed in order to access the synchronizeAll method of the child class
      #dummyChild.synchronizeAll
      dummyChild.synchronizeSynchronously(recursive)
      dummyChild.destroy

#      childClass.synchronizeAll unless childClass.nil?

    end
  end
  
  def self.synchronizeAllSynchronously(parents, recursive=false)
    verbose = true
		#abort parents.inspect

    # For each parent, perform the synchronization of all childs of the corresponding parent:
    parents.each do |myparent|
      responseBody = self.read(myparent)
		#p responseBody
		#abort responseBody
      # error handling:
      abort "synchronizeAllSynchronously(: ERROR: provisioningRequest timeout reached!" if responseBody.nil?

      # depending on the result, targetobject.provision can return a Fixnum. We need to convert this to a String
      responseBody = "synchronizeAllSynchronously: ERROR: #{self.class.name} does not exist" if responseBody.is_a?(Fixnum) && responseBody == 101

      p "SSSSSSSSSSSSSSSSSSSSSSSSS    #{self.name}.synchronizeAll responseBody    SSSSSSSSSSSSSSSSSSSSSSSSS" if verbose
      p responseBody.inspect if verbose
        
      # abort, if it is still a Fixnum:
      abort "synchronizeAllSynchronously: ERROR: wrong responseBody type (#{responseBody.class.name}) instead of String)" unless responseBody.is_a?(String)
      # business logic error:
      abort "received an ERROR response for provision(:read) in synchronizeAllSynchronously" unless responseBody[/ERROR.*$/].nil?
    
      require 'rexml/document'
      xml_data = responseBody
      doc = REXML::Document.new(xml_data)
      
      # we also want to update the status of elements that are in the DB but not on the target. 
      # For that, we need 1) collect all objects of the target, 2) remove all found objects, and 3) update the status of the remaining objects.
      # 1) collect all objects of the target
      if parentSym.nil?
        idsNotYetFound = self.all.map {|i| i.id }
      else
        idsNotYetFound = self.where(parentSym => myparent).map {|i| i.id }
      end
            # convert to array: .map {|i| i.id }
            #abort idsNotYetFound.inspect
            #abort self.find(idsNotYetFound[0]).inspect
      
      myparent.childClass.xmlElements(xml_data).each do |element|        
                #abort myparent.inspect

          # find corresponding site in the DB:
          thisObjects = self.find_from_REXML_element(element, myparent)
                    #abort thisObjects.inspect
         
          case thisObjects.count
            when 0
              # did not find object in the DB, so we create it:
              thisObject = self.create_from_REXML_element(element, myparent)
                    #abort thisObject.inspect
            when 1
              # found object in the DB:
              thisObject = thisObjects[0]
              
              # 2) remove all found objects from list
              idsNotYetFound.delete(thisObject.id)             
            else
              # found more than one match in the DB
              abort "too many matches"           
          end
          
          # TODO: the update_attribute and synchronizeSynchronously must be removed, when the create_from_REXML_element is enhanced to also update all parameters, including the status:        
              # note: update_attribute will save the object, even if the validations fail:
              thisObject.update_attribute(:status, 'found on target but not yet synchronized')
          
              # update the parameters of the specific object:
              thisObject.synchronizeSynchronously(recursive)
            
          thisObject.save!(validate: false)
  
      end # doc.root.elements["GetBGListData"].elements.each do |element|
      
      #3) update the status of the objects that are in the DB, but not configured on the target 
      idsNotFound = idsNotYetFound
      unless idsNotFound.empty?
        idsNotFound.each do |i|
          objectNotFound = self.find(i)
          objectNotFound.update_attribute(:status, 'not provisioned (seems to have been removed manually from target)') unless objectNotFound.status.match(/not provisioned/)
        end # idsNotFound.each do |i|
      end # unless idsNotFound.empty?
    end # parents.each do |target|
                #abort self.all.inspect
  end
  
  def self.read(myparent)
    methodNoun = "reading"
    # set body to be sent to the ProvisioningEngine target: e.g. inputBody = "action = Add Customer, customerName=#{name}"
    header = self.provisioningAction(:read, myparent)
		#abort inputBody.inspect
    return false if header.nil?  # no provisioningAction defined for this type

		#abort provisioningobject.inspect
    unless myparent.nil?
      headerAppend = myparent.recursiveConfiguration.gsub(/\r/, '')
      headerAppend = headerAppend.gsub(/^[\s]*\n/,'') # ignore empty lines
      headerAppend = headerAppend.gsub(/\n/, ', ')
      headerAppend = headerAppend.gsub(/,[\s]*\Z/, '')# remove trailing commas
    end
    
    header = header + ', ' + headerAppend unless headerAppend.nil?
    provisioning = Provisioning.new(action: header)
    object_sym = self.class.to_s.downcase.to_sym

    returnvalue = provisioning.deliver
  end
  
  def recursiveConfiguration
    if parent.nil?
      abort "could not read configuration for #{self.inspect}"
    else 
      parent.recursiveConfiguration
    end
  end

  def provision(method, async=true)

    provisioningobject = self

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

    # set body to be sent to the ProvisioningEngine target: e.g. inputBody = "action = Add Customer, customerName=#{name}" 
    inputBody = provisioningAction(method)
    return false if inputBody.nil?  # no provisioningAction defined for this type
    
    unless target.nil?
      actionAppend = target.configuration.gsub(/\r/, '')
      actionAppend = actionAppend.gsub(/^[\s]*\n/,'') # ignore empty lines
      actionAppend = actionAppend.gsub(/\n/, ', ')
      actionAppend = actionAppend.gsub(/,[\s]*\Z/, '')# remove trailing commas
    end

    # this will fail for old objects that do not yet obey to the validations:
    #update_attributes!(status: "waiting for #{methodNoun}")
    # it is better to update the status, even if the other validations might fail:
    update_attribute(:status, "waiting for #{methodNoun}") unless method == :read
    
    # recursive deletion of children (skipped in test mode):
    if inputBody.include?("Delete ") && !inputBody.include?("testMode") 
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
    
    @provisioning = Provisioning.new(action: inputBody, object_sym => provisioningobject)
              #abort @provisioning.inspect
    if method == :read || @provisioning.save
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
    
    # does not work yet?
    validates :provisioningtime, inclusion: {in: PROVISIONINGTIME}
end


