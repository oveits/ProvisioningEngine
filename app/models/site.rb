class ValidateCustomerExists < ActiveModel::Validator
  def validate(record)
      if Site.parentClass.exists? id: record.customer_id
        return true
      else
        record.errors[:customer_id] << "id=#{record.customer_id} does not exist in the database!"
      end
  end
end

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
          #raise Customer.exists?(record.customer_id).inspect
      targetName = Customer.find(record.customer_id).target.name unless record.customer_id.nil? || !Customer.exists?(record.customer_id)
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
    User.where(site: id).order(:extension)
  end
  
  def parent
    customer
  end
  
  def parentClass
    Customer
  end
  
  def self.parentClass
    Customer
  end
  
  def parentSym
    :customer
  end
  
  def self.parentSym
    :customer
  end

  def self.childClass
    User
  end
  
  def childClass
    User
  end
  
  def self.provisioningAction(method, myparent)     

    raise "Site.provisioningAction(method, myparent) called with invalid myparent" unless myparent.is_a?(Customer) && !myparent.name.nil?

    case method
      when :read
        "action=Show Sites, customerName=#{myparent.name}"
      else
        raise "unknown method for Site.provisioningAction(method)"
    end
  end
  
  def self.xmlElements(xml_data)
    trace = false
    
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
		#raise element.elements["SiteName"].text
    self.where(name: element.elements["SiteName"].text, customer: mytarget)
  end
  
  def self.create_from_REXML_element(element, mytarget)

    # read parameters from XML input
    params = {}
    {name: "SiteName", sitecode: "SiteCode", gatewayIP: "GatewayIP", countrycode: "CountryCode", areacode: "AreaCode", localofficecode: "LocalOfficeCode", extensionlength: "ExtensionLength"}.each do |key, value|
      params[key] = element.elements[value].text unless element.elements[value].nil?
    end
      params[:customer_id] = mytarget.id
		#raise params.inspect
		#raise element.elements["SiteName"].text

    # create new object with the above parameters, save it and return it
    myObject = self.new(params)
    myObject.save!(validate: false)
    return myObject
            	#raise self.new(name: element.elements["SiteName"].text, customer: mytarget).inspect
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
          raise "cannot de-provision a site without name"
        end
        
        if customer.nil?
          raise "cannot de-provision a site without customer"
        end
        
        if customer.name.nil?
          raise "cannot de-provision a site with a customer with no name"
        end

        "action=Delete Site, SiteName=#{name}, customerName=#{customer.name}"
      when :read
        if name.nil?
	  "action=Show Sites, customerName=#{customer.name}"
        else
	  "action=Show Sites, SiteName=#{name}, customerName=#{customer.name}"
        end
      else
        raise "Unsupported provisioning method"
    end
  end

  validIPAddressRegex = /\A(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\Z/
  validRFC952HostnameRegex = /\A(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])\Z/
  
  belongs_to :customer
  validates :customer_id, presence: true 
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
  validates_with ValidateCustomerExists

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
