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

class Validate_OfficeCode < ActiveModel::Validator
  def validate(record)
    
    
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
  #
  # INIT
  #
#  class Regexp
#    # concatenation of two regex
#    def +(r)
#      Regexp.new(source + r.source)
#    end
#  end

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
  
  def provisioningAction(method)
   
    if name.nil?
      abort "cannot de-provision a site without name"
    end
    
    if customer.nil?
      abort "cannot de-provision a site without customer"
    end
    
    if customer.name.nil?
      abort "cannot de-provision a site with a customer with no name"
    end
    
    case method
      when :create
        #"action=Add Site, siteName=#{name}, #customerName=#{customer.name}"
        inputBody = "action=Add Site, customerName=#{customer.name}, SiteName=#{name}, SC=#{sitecode}"          
        inputBody += ", GatewayIP=#{gatewayIP}, CC=#{countrycode}, AC=#{areacode}, LOC=#{localofficecode}, XLen=#{extensionlength}"       
        inputBody += ", EndpointDefaultHomeDnXtension=#{mainextension}"
        return inputBody
      when :destroy
        "action=Delete Site, SiteName=#{name}, customerName=#{customer.name}"
      else
        abort "Unsupported provisioning method"
    end
  end

# TODO: remove after successful test
#  def de_provision(async=true)
#    @object = self
#    @method = "Delete"
#    @className = @object.class.to_s
#    @classname = @className.downcase
#    @parentClassName = "Customer"
#    @parentclassname = @parentClassName.downcase
#    
##abort self.inspect
##abort @parentclassname
#    
#    unless @object.customer.nil?
#      provisioningAction = "action=#{@method} #{@className}, #{@classname}Name=#{@object.name}, #{@parentclassname}Name=#{@object.customer.name}" 
##abort provisioningAction
#      provisionNew(provisioningAction, async)
#    else
#      abort "cannot de-provision a site without specified customer"
#    end
#  end

# TODO: remove after successful test  
#  def provisionOld(inputBody, async=true)
#
#    @site = Site.find(id)
#    @customer = @site.customer
#    # e.g. inputBody = "action = Add Customer, customerName=#{name}" 
#    
#    unless @customer.nil? || @customer.target_id.nil?
#      @target = Target.find(@customer.target_id)
#      actionAppend = @target.configuration.gsub(/\n/, ', ')
#      actionAppend = actionAppend.gsub(/\r/, '')
#    end
#    
#    # recursive deletion of users:
#    @users = User.where(site: id)
#    @users.each do |user|
#      inputBodyUser = "action=Delete User, X=#{user.extension}, customerName=#{@customer.name}, SiteName=#{@site.name}"
#      inputBodyUser = inputBodyUser + ', ' + actionAppend unless actionAppend.nil?
#      user.provision(inputBodyUser, async)
#    end
#    
#    # deletion of site:
#    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?
#
#    @provisioning = Provisioning.new(action: inputBody, site: @site, customer: @customer)
#    
#    if @provisioning.save
#       #@provisioning.createdelayedjob
#       #@provisioning.deliver
#       if async == true
##p "=============== models/sites.rb:provision: performing @provisioning.deliverasynchronously ============"
#         @provisioning.deliverasynchronously
#       else
##p "=============== models/sites.rb:provision: performing @provisioning.deliver ============"
#         @provisioning.deliver
#       end
#       # success
#       return 0
#    else
#      @provisioning.errors.full_messages.each do |message|
#        abort 'provisioning error: ' + message.to_s
#      end
#    end 
#  end # def
  
  validIPAddressRegex = /\A(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\Z/
  validRFC952HostnameRegex = /\A(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])\Z/

#  p 'RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR'
#  p validIPAddressRegex.source
#  p Regexp.new(validIPAddressRegex.source) # + validRFC952HostnameRegex.source)
#  p 'RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR'
  
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
  validates_format_of :gatewayIP, :with => Regexp.new('\A\Z|' + validIPAddressRegex.source + '|' + validRFC952HostnameRegex.source), message: "must be either empty or a valid IP address or Domain Name" 
  validates_format_of :countrycode, :with => /\A[1-9][0-9]{0,}\Z/, message: "must be a number"
  validates_format_of :areacode, :with => /\A[1-9][0-9]{0,}\Z/, message: "must be a number"
  validates_format_of :localofficecode, :with => /\A[1-9][0-9]{0,}\Z/, message: "must be a number"
  validates_format_of :extensionlength, :with => /\A[1-9]$|^1[1-2]\Z/, message: "must be a number between 1..12" 
  validates_with Validate_OfficeCode, Validate_MainExtension
  validates_with Validate_Sitecode 
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
