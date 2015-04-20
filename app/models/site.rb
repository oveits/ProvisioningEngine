class Validate_Sitecode < ActiveModel::Validator
  def validate(record)

    # allow for NULL sitecode:
    return true if record.sitecode.nil? || record.sitecode == ""

    # find all sites with the requested sitecode
    @sites = Site.where(sitecode: record.sitecode)

    # for update_attributes, which is saving the object, we need to exclude the "this" site. 
    # Otherwise, this validation would always fail, if the site is saved already 
    @sites = @sites.where.not(id: record.id) unless record.id.nil?

    duplicate = false
    @sites.each do |site|
      if site.customer.target == record.customer.target
        duplicate = true
        break
      end
    end

    if duplicate
      record.errors["Sitecode [#{record.sitecode}]"] << "is already taken for target \"#{record.customer.target.name}\"!"
    end

  end # def
end

class Validate_Sitecode_V7R1 < ActiveModel::Validator
  def validate(record)
    # for OSV V7R1, empty sitecodes are not supported
    if record.sitecode.nil? || record.sitecode == ""
      targetName = Customer.find(record.customer_id).target.name unless record.customer_id.nil?
      if record.customer_id.nil? || /V7R1/.match(targetName)
        record.errors[:sitecode] << "must not be empty for V7R1 targets"
      end 
    end 
  end
end

class Validate_OfficeCode < ActiveModel::Validator
  def validate(record)
    
    # we do not want to validate the officecodelength if one of the following variables are not defined:
    return true if  record.countrycode.nil? ||  record.areacode.nil? ||  record.localofficecode.nil? ||  record.extensionlength.nil?

    officecodelength = record.countrycode.length + record.areacode.length + record.localofficecode.length + record.extensionlength.to_i
    
    if officecodelength > 15
      record.errors["Office Code [#{record.countrycode} (#{record.areacode}) #{record.localofficecode} + extension]"] << "length must <= 15 but is #{officecodelength.to_s}"
    end 
    
  end # def
end

class Validate_MainExtension < ActiveModel::Validator
  def validate(record)
    
    # mainextension is defined as the representative homeDN of the local GW. If there is no local GW, the mainextension is nil
    if record.gatewayIP.nil?
      return nil
    else 
      mainextensionlength = record.mainextension.length 
    end 
    
    unless mainextensionlength == record.extensionlength.to_i 
      record.errors["Main Extension [#{record.mainextension}]"] << "length is is #{mainextensionlength.to_s}, but must match the #{:extensionlength}=#{record.extensionlength}"
    end 
    
  end # def
end


class Site < Provisioningobject #< ActiveRecord::Base

  def target
    Target.find(customer.target_id) unless customer.nil? || customer.target_id.nil?
  end
  
  def children
    children = User.where(site: id)
    if children.count > 0
      children
    else
      nil
    end
  end
  
  def parent
    customer
  end
  
  def parentClass
    Customer
  end
  
  def parentSym
    :customer
  end
  
  def self.parentSym
    :customer
  end
  
  def self.parentClass
    Customer
  end

  def self.childClass
    User
  end
  
  def childClass
    User
  end
  
  def self.provisioningAction(method)
     "action=Show Sites"
  end
  
  def self.xmlElements(xml_data)
    trace = true
    
    doc = REXML::Document.new(xml_data)
    
    myelement = doc.root.elements["Sites"]
    
            if trace
              p "xmlElements(xml_data): Before removing CNP"
              myelement.elements.each do |element|
                p element.name
                p element.text
                element.elements.each do |innerelement|
                  p innerelement.name
                  p innerelement.text
                end
              end      
            end
    
    myelement.elements.each do |element|
      myelement.delete_element(element) if /\ACNP_/.match(element.elements["NumberingPlanName"].text)
    end  

            if trace
              p "xmlElements(xml_data): After removing CNP"
              myelement.elements.each do |element|
                p element.name
                p element.text
                element.elements.each do |innerelement|
                  p innerelement.name
                  p innerelement.text
                end
              end      
            end   
    
    myelement.elements
  end
  
  def self.find_from_REXML_element(element, mytarget)
    self.where(name: element.elements["SiteName"].text, customer: mytarget)
  end
  
  def self.create_from_REXML_element(element, mytarget)
    self.new(name: element.elements["SiteName"].text, customer: mytarget)
  end
  
  def provisioningAction(method)
   
    case method
      when :create
        #"action=Add Site, siteName=#{name}, #customerName=#{customer.name}"
        inputBody = "action=Add Site, customerName=#{customer.name}, SiteName=#{name}, SC=#{sitecode}"          
        inputBody += ", GatewayIP=#{gatewayIP}, CC=#{countrycode}, AC=#{areacode}, LOC=#{localofficecode}, XLen=#{extensionlength}"       
        inputBody += ", EndpointDefaultHomeDnXtension=#{mainextension}"
        return inputBody
      when :destroy
        if name.nil?
          abort "cannot de-provision a site without name"
        end
        
        if customer.nil?
          abort "cannot de-provision a site without customer"
        end
        
        if customer.name.nil?
          abort "cannot de-provision a site with a customer with no name"
        end

        "action=Delete Site, SiteName=#{name}, customerName=#{customer.name}"
      when :read
        if name.nil?
	  "action=Show Sites, customerName=#{customer.name}"
        else
	  "action=Show Sites, SiteName=#{name}, customerName=#{customer.name}"
        end
      else
        abort "Unsupported provisioning method"
    end
  end

  def self.synchronizeAll(targets = nil, async=true, recursive=false)

    # TODO: create rspec tests for recursive synchronizeAll, if not already present
    # TODO: test with recursive = true
    # TODO: replace dummyChild method by native childClass.synchronizeAll in app/models/provisioningobject.rb def synchronizeSynchronously(recursive=true)
recursive = false
    targets ||= parentClass.all
    if async || recursive
      returnBody = delay.synchronizeAllSynchronously(targets, recursive)
                    #abort self.all.inspect
    else
      returnBody = synchronizeAllSynchronously(targets, recursive)
                    #abort self.all.inspect
    end
  end
  
#TODO: remove after successful test
if false  
  def self.synchronizeAllSynchronouslyOld(targets, recursive=false)
    verbose = true
    targets.each do |mytarget|
      responseBody = self.read(mytarget)
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
      idsNotYetFound = self.where(customer: mytarget).map {|i| i.id }
            # convert to array: .map {|i| i.id }
            #abort idsNotYetFound.inspect
            #abort self.find(idsNotYetFound[0]).inspect
      
      doc.root.elements["Sites"].elements.each do |element|
          # skip the common numbering plan (does not correspond to a real site)
          next if /\ACNP_/.match( element.elements["NumberingPlanName"].text )         
                #abort mytarget.inspect

          # find corresponding site in the DB:
          thisObjects = self.where(name: element.elements["SiteName"].text, customer: mytarget)
          
          case thisObjects.count
            when 0
              # did not find object in the DB, so we create it:
              thisObject = self.new(name: element.elements["SiteName"].text, customer: mytarget)
            when 1
              # found object in the DB:
              thisObject = thisObjects[0]
              
              # 2) remove all found objects from list
              idsNotYetFound.delete(thisObject.id)
                    #abort idsNotYetFound.inspect              
            else
              # found more than one match in the DB
              abort "too many matches"           
          end
          
          # note: update_attribute will save the object, even if the validations fail:
          thisObject.update_attribute(:status, 'found on target but not yet synchronized')
          #UpdateDB.new.perform(thisObject)
          thisObject.synchronizeSynchronously(recursive)
            
          thisObject.save!(validate: false)
  
      end # doc.root.elements["GetBGListData"].elements.each do |element|
      
      #3) update the status of the objects that are in the DB, but not configured on the target 
      idsNotFound = idsNotYetFound
      unless idsNotFound.empty?
        idsNotFound.each do |i|
          objectNotFound = self.find(i)
                #abort objectNotFound.inspect         
          objectNotFound.update_attribute(:status, 'not provisioned (seems to have been removed manually from target)') unless objectNotFound.status.match(/not provisioned/)
        end
      end
    end # targets.each do |target|
                #abort self.all.inspect
  end
end # if false

  
  validIPAddressRegex = /\A(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\Z/
  validRFC952HostnameRegex = /\A(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])\Z/
  
  belongs_to :customer
  validates :customer, presence: true 
  has_many :users, dependent: :destroy
  validates :name,  presence: true,
                    uniqueness: { scope: :customer, message: "is already taken for this customer" },
                    length: { in: 3..20  }
  validates_format_of :name, :with => /\A[a-zA-Z][a-zA-Z0-9\-\.]+\Z/, message: "must start with a character a-z or A-Z and can contain characters, numbers, '-' and '.'"
  #validates :sitecode, presence: true
  #validates_format_of :countrycode, :with => /\A44\Z|\A49\Z/, message: "currently only 44 or 49 supported"
  validates :countrycode, inclusion: {in: COUNTRYCODES, message: "currently only supported for one of the values #{COUNTRYCODES.inspect.gsub('"', '')}"} #COUNTRYCODES.inspect
  validates_format_of :sitecode, :with => /\A\Z|\A[1-9][0-9]{0,6}\Z/, message: "must be a number of length 1 to 7" 
  # FQDN not yet supported:
  #validates_format_of :gatewayIP, :with => Regexp.new('\A\Z|' + validIPAddressRegex.source + '|' + validRFC952HostnameRegex.source), message: "must be either empty or a valid IP address or Domain Name" 
  validates_format_of :gatewayIP, :with => Regexp.new( '\A\Z|' + validIPAddressRegex.source ), message: "must be either empty or a valid IP address" 
  validates_format_of :countrycode, :with => /\A[1-9][0-9]{0,}\Z/, message: "must be a number"
  validates_format_of :areacode, :with => /\A[1-9][0-9]{0,}\Z/, message: "must be a number"
  validates_format_of :localofficecode, :with => /\A[1-9][0-9]{0,}\Z/, message: "must be a number"
  validates_format_of :extensionlength, :with => /\A[1-9]$|^1[1-2]\Z/, message: "must be a number between 1..12" 
  validates_with Validate_OfficeCode, Validate_MainExtension
  validates_with Validate_Sitecode 
  validates_with Validate_Sitecode_V7R1
  validates :sitecode, unique_on_target: true 
  validates :mainextension, unique_on_target: {:scope => [:countrycode, :areacode, :localofficecode]} 
  validates :gatewayIP, unique_on_target: true 

  # does not work:
  #validates :gatewayIP, uniqueness: { scope: :target, message: "is already taken for this target" }
  
  
  #attr_readonly :all
  #attr_accessible :name
#
#  # make all fields accessible to the admin:
#  columns.each do |column|
#    attr_accessible column.name.to_sym, :as => :admin
#    attr_accessible column.name.to_sym # any user
#  end
              
end
