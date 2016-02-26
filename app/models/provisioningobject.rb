class Provisioningobject < ActiveRecord::Base
  self.abstract_class = true # makes the model abstract

  PROVISIONINGTIME = [PROVISIONINGTIME_IMMEDIATE = 'immediate', PROVISIONINGTIME_AD_HOC = 'ad-hoc'] # PROVISIONINGTIME_SCHEDULED = 'scheduled'

  # allow transient attribute (i.e. an attribute that is not mapped to a column in the database)
  attr_accessor :provisioningtime
 
  after_initialize :init
  
  def self.all_in(ancestor=nil) #, pagination = false, page=1, items_per_page=50)
    #
    # returns all provisioningobjects found in the DB as Array; 
    # if ancester is not nil, it returns only the descendants of this ancestor (e.g. for showing GET /targets/1/sites will show only the sites of target 1
    # all_in has helped to reduce the number of SQL queries for large indices: only one SQL query per level (Target/Customer/Site/User) instead of N+1 queries per level
    #

    # calculate list of parents; go down the tree in order to save SQL queries:
    # with this method, only 3 SQL statements are needed to find the Site of a Target: 
    # 1) get the Target, 
    # 2) get all Customers of this target, 
    # 3) get all Sites and filter by the list of Customers (filtering done in memory on an array) 
    #raise ancestor.inspect

    # find all parents recursively. Start at ancestor level, e.g. at the target
    if ancestor.nil?
      #filtered_all = Target.all.map {|i| i }
      #filtered_all = Target.order(created_at: :desc).map {|i| i }
      filtered_all = Target.order(:name).map {|i| i }
    else
      filtered_all = [ancestor]
    end
    
    # return immediately, if no ancestor and no Target is defined:
    if filtered_all.count == 0
      return self.all.map {|i| i}
    end

            #raise Target.all.inspect
            #raise filtered_all.inspect
            #raise ancestor.inspect
    children_list = []
    #currentClass = ancestor.class
    currentClass = filtered_all[0].class
           #raise currentClass.inspect
    while currentClass != self # stop if you have found all parents. E.g. if you search for all Sites of the Target, we will stop if we have found all Customers

      # for all parents in the list, find all children and write them to the children_list
      filtered_all.each do |parent|
        children_list = children_list.concat parent.children unless parent.children.nil?
      end

      # go down one level, e.g. if you have found all Customers of a Target, write the Customers to the parent_list, in case of searched Sites, we stop here. In case of Users being looked for, we go one step further and will find all children of the Customers in the next iteration
      filtered_all = children_list
            #raise filtered_all.inspect if filtered_all[0].is_a?(Customer)
            #raise filtered_all.inspect if filtered_all[0].is_a?(Site)
            #raise filtered_all.inspect if filtered_all[0].is_a?(User)
      children_list = []
      currentClass = currentClass.childClass
    end # while currentClass != parentClass
    
            #raise filtered_all.inspect

    return filtered_all
  end # def self.all_in(ancestor=nil)


  def self.all_inOld(ancestor=nil, pagination = false, page=1, items_per_page=50)
    #
    # returns all provisioningobjects found in the DB as Array; 
    # if ancester is not nil, it returns only the descendants of this ancestor (e.g. for showing GET /targets/1/sites will show only the sites of target 1
    # all_in als has helped to reduce the number of SQL queries for large indices (e.g. only one SQL query instead of N+1 queries)
    #

    # return all, if ancestor is nil, but paginate, if requested

    first_index_of_page = (page-1) * items_per_page if pagination
    last_index_of_page = page * items_per_page - 1 if pagination

    if ancestor.nil?
      if pagination
        pagedReturn = self.all.map {|i| i }[first_index_of_page..last_index_of_page]
        pagedReturn = [] if pagedReturn.nil?
		#raise pagedReturn.inspect
        return pagedReturn
      else
              raise self.all.map {|i| i }.inspect
        return self.all.map {|i| i }
      end
    end

raise "djköshgoöesrhriogörwheögwiöho"
    # perform single SQL query with filter, if filtered per parent, e.g. GET /customers/1/sites
    if ancestor.is_a?(parentClass)
      # single parent

      # e.g. :target_id
      parent_id_sym = "#{parentClass.name.downcase}_id".to_sym
      return self.where(parent_id_sym => ancestor.id).map {|i| i }
    end unless parentClass.nil?
#raise ancestor.inspect

    # calculate list of parents; go down the tree in order to save SQL queries:
    # with this method, only 3 SQL statements are needed to find the Site of a Target: 
    # 1) get the Target, 
    # 2) get all Customers of this target, 
    # 3) get all Sites and filter by the list of Customers (filtering done in memory on an array) 
		#raise ancestor.inspect

    # find all parents recursively. Start at ancestor level, e.g. at the target
    filtered_all = [ancestor]
          raise filtered_all.inspect 
    children_list = []
    currentClass = ancestor.class
    while currentClass != self # stop if you have found all parents. E.g. if you search for all Sites of the Target, we will stop if we have found all Customers

      # for all parents in the list, find all children and write them to the children_list
      filtered_all.each do |parent|
        children_list = children_list.concat parent.children unless parent.children.nil?
      end

      # go down one level, e.g. if you have found all Customers of a Target, write the Customers to the parent_list, in case of searched Sites, we stop here. In case of Users being looked for, we go one step further and will find all children of the Customers in the next iteration
      filtered_all = children_list
            raise filtered_all.inspect 
      children_list = []
      currentClass = currentClass.childClass
    end # while currentClass != parentClass

    # handle pagination, if needed:
    if pagination
      return filtered_all[first_index_of_page..last_index_of_page]
    else
      return filtered_all
    end
  end # def self.all_inOld(ancestor=nil, pagination = false, page=1, items_per_page=50)

  def init
    self.status ||= 'not provisioned'
  end

  def provisioningtime
    @provisioningtime.nil? ? PROVISIONINGTIME_IMMEDIATE : @provisioningtime
  end
  
  def new
  end
  
  def path(prefix)
    raise "method path() in app/models/provisioningobject.rb is broken. Fix before use. E.g. see app/views/shared/_helpers.html.erb->provisioningobject_path() for a correctly working example"
    prefixPrepend = "#{prefix}_" unless prefix.nil? 
    #return send("#{prefix}#{myobject(thisobject.class.to_s)}_path", thisobject.id)
    #raise send("#{prefix}#{self.class.name.downcase}_path").inspect if prefix == 'deprovision_'
    #raise self.id.inspect if prefix == 'deprovision_'
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
    #raise @provisionings.inspect
    
    # search for active jobs:
    @provisionings.each do |provisioning|    
      return true if provisioning.activeJob?
    end
    
    # else return false:
    return false
  end
  
  def provisioned?
    case status
      when /was already de-provisioned|not provisioned/
        false
      when /provisioned success|provisioning success|failed \(import errors\)|deletion failed|waiting for deletion/
        true
      else
        false
    end
  end
  
  def synchronize(async=true, recursive=true)
		#raise async.inspect
    #return false if /waiting|progress/.match(status)
    #updateDB = UpdateDB.new
    if async

      # the next line had lead to a severe bug with error message "SQLite3::BusyException: database is locked", if the customer validates_format_of name was wrong (:name, :with => /\A[A-Z,a-z,0-9,_]{0,100}+\Z/ instead of :name, :with => /\A[A-Z,a-z,0-9,_]{0,100}\Z/)
      #update_attributes(:status => 'synchronization in progress')
      # works fine in any case, since the validations are skipped:
      update_attribute(:status, 'synchronization in progress')

      #returnBody = updateDB.delay.perform(self)
      # or:
      #returnBody = delay.synchronizeSynchronously(recursive)
      # replaced by:
      #job = 
      GeneralJob.perform_later(self, "synchronizeSynchronously")
      #raise GeneralJob.all.inspect
      # for testing the cancel function: should raise an raise with message "true", if sleep is commented out. Else it should raise an raise with message "false"
      # sleep 10.seconds
      #raise job.cancel.inspect
       
      
      #returnBody = synchronizeSynchronously(recursive)
    else
      #returnBody = updateDB.perform(self)
      # or:
      #returnBody = 
      synchronizeSynchronously(recursive)
    end
  end

  def self.synchronizeTree(ancestor = nil, async=true, recursive=false)
    # TODO: synchronizeTree is experimental and not used by any 
    #
    # synchronizes all objects of the specific class to the local database
    # with recursive == true, also the child classes are synchronized
    #
    # TODO: create rspec tests for recursive synchronizeAll, if not already present and test with recursive = true (also see controller)

    raise "recursive mode of synchronizeAll is not yet supported" if recursive

    if ancestor.nil?
      targetsArray = Target.all.map {|i| i}
    else
      targetsArray = [ ancestor.target ] unless ancestor.nil?
    end
		#raise targetsArray.inspect

    parents_all = parentClass.all_in(ancestor) unless ancestor.nil?
    parents_all = parentClass.all_in if ancestor.nil?
    
    targetsArray.each do |target_i|
      parents = parents_all unless ancestor.nil?
      parents = parents_all.select{ |i| i.target == target_i } if ancestor.nil?

    end

raise parents.inspect    
    # TODO: rebuild the functions of self.synchronizeAll with less SQL requests.
    # idea: build a tree from ancestor (or root) to the to be updated level. 
    # It should be possible to find the anchestors without any additional SQL statement (e.g. if user = tree[target_i][customer_i][site_i][user_i] then user.customer = tree[target_i][customer_i]. 
    # e.g. Loop through each level similar to what I already have done in the customer's index view
    #  
    # 
    
  end
  
  def self.synchronizeAll(parents = nil, async=true, recursive=false, abortOnAbort=false)
    # 
    # synchronizes all objects of the specific class to the local database
    # with recursive == true, also the child classes are synchronized
    # 
    # TODO: create rspec tests for recursive synchronizeAll, if not already present and test with recursive = true (also see controller)

#raise  abortOnAbort.inspect
  
    raise "recursive mode of synchronizeAll is not yet supported" if recursive

    parents ||= parentClass.all_in
		#raise parents.inspect

    # find target systems involved:
    targetsArray = parents.map {|i| i.target}.uniq
		#raise targetsArray.inspect

    # for each target involved, perform a synchronization task (in the background for async==true):
    targetsArray.each do |target_i|

		# for tests:
		#next unless target_i.name.match(/CSL9DEV/)

      # For each target, find all parents, which are in the parents list and are on this target
      parents_of_this_target = parents.select{ |i| i.target.id == target_i.id} #targetsArray 
		#raise parents_of_this_target.inspect

      # perform synchronizeAllSynchronously(parents_of_this_target, recursive)
      if async
        # delayed jobs automatically rescues on raise and retries the synchronization. If we do not want to retry on raise, we can set @abortOnAbort to false in the provisioningobjects controller
        delay.synchronizeAllSynchronously(parents_of_this_target, recursive, abortOnAbort)
      else # if async
        # if @abortOnAbort is set to false in the provisioningobjects controller, we rescue the raise and continue with other targets, if a target synchronization fails:
        # (in development mode, for troubleshooting, it is sometimes better not to rescue on raise, though)
        synchronizeAllSynchronously(parents_of_this_target, recursive, abortOnAbort)          
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
            #raise "model: synchronize" + self.inspect
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
  
  def self.synchronizeAllSynchronously(parents, recursive=false, abortOnAbort=true)
    
    # if abortOnAbort is false, we wrap the whole function in a begin rescue block and only print the Exception message to the standard output:
    unless abortOnAbort
      begin
        result = synchronizeAllSynchronously(parents, recursive, true)
        return result
      rescue Exception => e
        #p "#{self.name}.synchronizeAllSynchronously: #{e.message}"
        return false
      end
    end
    
    #else the rest of the function is performed:
    
    verbose = false
		#raise parents.inspect

    # For each parent, perform the synchronization of all childs of the corresponding parent:
    parents.each do |myparent|
      responseBody = self.read(myparent)
		#p responseBody
		#raise responseBody
      # error handling:
      raise "synchronizeAllSynchronously(: ERROR: provisioningRequest timeout reached!" if responseBody.nil?

      # depending on the result, targetobject.provision can return a Fixnum. We need to convert this to a String
      responseBody = "synchronizeAllSynchronously: ERROR: #{self.name} does not exist" if responseBody.is_a?(Fixnum) && responseBody == 101
#raise "lerghoesrhgoerhgos"

      #p "SSSSSSSSSSSSSSSSSSSSSSSSS    #{self.name}.synchronizeAll responseBody    SSSSSSSSSSSSSSSSSSSSSSSSS" if verbose
      p responseBody.inspect if verbose
        
      # raise, if it is still a Fixnum:
      return "synchronizeAllSynchronously: ERROR: wrong responseBody type (#{responseBody.class.name}) instead of String)" unless responseBody.is_a?(String)
      #raise "synchronizeAllSynchronously: ERROR: wrong responseBody type (#{responseBody.class.name}) instead of String)" unless responseBody.is_a?(String)
      # business logic error:
      #raise "received an ERROR response for provision(:read) in synchronizeAllSynchronously" unless responseBody[/ERROR.*$/].nil?
      next unless responseBody[/ERROR.*$/].nil?
    
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
            #raise idsNotYetFound.inspect
            #raise self.find(idsNotYetFound[0]).inspect
      
      myparent.childClass.xmlElements(xml_data).each do |element|        
                #raise myparent.inspect

          # find corresponding site in the DB:
          thisObjects = self.find_from_REXML_element(element, myparent)
                    #raise thisObjects.inspect
         
          case thisObjects.count
            when 0
              # did not find object in the DB, so we create it:
              thisObject = self.create_from_REXML_element(element, myparent)
                    #raise thisObject.inspect

              # update status:
              thisObject.update_attribute(:status, 'provisioned successfully (found on target and  thus created in the database)')

            when 1
              # found object in the DB:
              thisObject = thisObjects[0]
                            
              # 2) remove all found objects from list
              idsNotYetFound.delete(thisObject.id)             
            else
              # found more than one match in the DB
              raise "too many matches"           
          end
          
		#raise thisObject.status
  
      end # doc.root.elements["GetBGListData"].elements.each do |element|
      
      #3) update the status of the objects that are in the DB, but not configured on the target 
      idsNotFound = idsNotYetFound
                #raise idsNotFound.inspect
      unless idsNotFound.empty?
        idsNotFound.each do |i|
          objectNotFound = self.find(i)
                #raise objectNotFound.inspect
          objectNotFound.update_attribute(:status, 'not provisioned (seems to have been removed manually from target)') unless objectNotFound.status.match(/not provisioned/)
                #raise objectNotFound.inspect if objectNotFound.name == "Customer3"
        end # idsNotFound.each do |i|
      end # unless idsNotFound.empty?
    end # parents.each do |target|
                #raise self.all.inspect
  end
  
  def self.read(myparent)
    methodNoun = "reading"
    # set body to be sent to the ProvisioningEngine target: e.g. inputBody = "action = Add Customer, customerName=#{name}"
    header = self.provisioningAction(:read, myparent)
		#raise inputBody.inspect
    return false if header.nil?  # no provisioningAction defined for this type

		#raise provisioningobject.inspect
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

  def self.recursiveDeleteAll
    #
    # deletes the contents of an SQL table with a single SQL command (much better performance than self.destroy_all)
    # deletes all children tables recursively
    #
    childClass.recursiveDeleteAll unless childClass.nil?
		#raise childClass.inspect
    self.delete_all
  end
  
  def recursiveConfiguration
    if parent.nil?
      raise "could not read configuration for #{self.inspect}"
    else 
      parent.recursiveConfiguration
    end
  end

  def provision(method, async=true)

    provisioningobject = self
		#raise provisioningobject.inspect
		#raise method.inspect

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
        raise "provision(method=#{method}, async=#{async}): Unknown method"
    end

    # set body to be sent to the ProvisioningEngine target: e.g. inputBody = "action = Add Customer, customerName=#{name}" 
    inputBody = provisioningAction(method)
        #raise inputBody.inspect
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
#      readList = self.parent.provision(:read, false)
#            raise readList.inspect

      # confusing "exists already" error in the Provisioning Tasks list, in case a parent is provisioned already, but I still try to provision it:
#      self.parent.provision(:create, async) unless self.parent.nil?
      # get rid of the "exists already" error. Drawback: if the parent is not provisioned, but out local database does not know that it is provisioned, we will get an error.
      # TODO: update provisioned? status via readList = self.parent.provision(:read, false). Own method?
      self.parent.provision(:create, async) unless self.parent.provisioned?
    end 
    
    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?

    object_sym = :provisioningobject
    
    @provisioning = Provisioning.new(action: inputBody, object_sym => provisioningobject)
              #raise @provisioning.inspect
              #raise @provisioning.action.inspect
              #raise method.inspect
              #raise async.inspect
    if method == :read || @provisioning.save
       if async == true
         returnvalue = @provisioning.deliverasynchronously
       else
              #raise @provisioning.inspect
              #raise @provisioning.action.inspect
         returnvalue = @provisioning.deliver
       end
    else
      @provisioning.errors.full_messages.each do |message|
        raise 'provisioning error: ' + message.to_s
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


