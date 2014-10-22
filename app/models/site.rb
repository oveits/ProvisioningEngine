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
    
    mainextensionlength = record.mainextension.length 
    
    unless mainextensionlength == record.extensionlength.to_i 
      record.errors["Main Extension [#{record.mainextension}]"] << "length is is #{mainextensionlength.to_s}, but must match the #{:extensionlength}=#{record.extensionlength}"
    end 
    
  end # def
end


class Site < ActiveRecord::Base
  #
  # INIT
  #
#  class Regexp
#    # concatenation of two regex
#    def +(r)
#      Regexp.new(source + r.source)
#    end
#  end
  
  def provision(inputBody, async=true)

    @site = Site.find(id)
    @customer = @site.customer
    # e.g. inputBody = "action = Add Customer, customerName=#{name}" 
    
    unless @customer.nil? || @customer.target_id.nil?
      @target = Target.find(@customer.target_id)
      actionAppend = @target.configuration.gsub(/\n/, ', ')
      actionAppend = actionAppend.gsub(/\r/, '')
    end
    
    # recursive deletion of users:
    @users = User.where(site: id)
    @users.each do |user|
      inputBodyUser = "action=Delete User, X=#{user.extension}, customerName=#{@customer.name}, SiteName=#{@site.name}"
      inputBodyUser = inputBodyUser + ', ' + actionAppend unless actionAppend.nil?
      user.provision(inputBodyUser, async)
    end
    
    # deletion of site:
    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?

    @provisioning = Provisioning.new(action: inputBody, site: @site, customer: @customer)
    
    if @provisioning.save
       #@provisioning.createdelayedjob
       #@provisioning.deliver
       if async == true
#p "=============== models/sites.rb:provision: performing @provisioning.deliverasynchronously ============"
         @provisioning.deliverasynchronously
       else
#p "=============== models/sites.rb:provision: performing @provisioning.deliver ============"
         @provisioning.deliver
       end
       # success
       return 0
    else
      @provisioning.errors.full_messages.each do |message|
        abort 'provisioning error: ' + message.to_s
      end
    end 
  end # def
  
  validIPAddressRegex = /\A(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\Z/
  validRFC952HostnameRegex = /\A(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])\Z/

#  p 'RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR'
#  p validIPAddressRegex.source
#  p Regexp.new(validIPAddressRegex.source) # + validRFC952HostnameRegex.source)
#  p 'RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR'
  
  belongs_to :customer
  has_many :users, dependent: :destroy
  validates :name,  presence: true,
                    uniqueness: { scope: :customer, message: "is already taken for this customer" },
                    length: { in: 3..20  }
  validates :sitecode, presence: true
  validates_format_of :sitecode, :with => /\A[1-9][0-9]{0,6}\Z/, message: "must be a number of length 1 to 7" 
  validates_format_of :gatewayIP, :with => Regexp.new('\A\Z|' + validIPAddressRegex.source + '|' + validRFC952HostnameRegex.source), message: "must be either empty or a valid IP address or Domain Name" 
  validates_format_of :countrycode, :with => /\A[1-9][0-9]{0,}\Z/, message: "must be a number"
  validates_format_of :areacode, :with => /\A[1-9][0-9]{0,}\Z/, message: "must be a number"
  validates_format_of :localofficecode, :with => /\A[1-9][0-9]{0,}\Z/, message: "must be a number"
  validates_format_of :extensionlength, :with => /\A[1-9]$|^1[1-2]\Z/, message: "must be a number between 1..12" 
  validates_with Validate_OfficeCode, Validate_MainExtension 
  
  
  #attr_readonly :all
  #attr_accessible :name
#
#  # make all fields accessible to the admin:
#  columns.each do |column|
#    attr_accessible column.name.to_sym, :as => :admin
#    attr_accessible column.name.to_sym # any user
#  end
              
end
