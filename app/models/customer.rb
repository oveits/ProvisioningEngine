class ValidateLanguage < ActiveModel::Validator
  def validate(record)
    #abort record.inspect
    # returnString = @customer.provision("testMode=testMode, action=Add Customer, customerName=#{customer_params[:name]}")
  end
end

class ValidateWithProvisioningEngine < ActiveModel::Validator
  def validate(record)
    # returnString = @customer.provision("testMode=testMode, action=Add Customer, customerName=#{customer_params[:name]}")
  end
end
class ValidateWithProvisioningEngine_old < ActiveModel::Validator
  def validate(record)
    require "net/http"
    require "uri"
    
    #uri = URI.parse("http://localhost/CloudWebPortal")
    uri = URI.parse(ENV["PROVISIONINGENGINE_CAMEL_URL"])
    
    #response = Net::HTTP.post_form(uri, {"testMode" => "testMode", "offlineMode" => "offlineMode", "action" => "Add Customer", "customerName" => @customer.name})
    #OV replaced by (since I want to control the timers):
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 2
    http.read_timeout = 4
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({"testMode" => "testMode", "action" => "Add Customer", "customerName" => record.name})
    
    begin
      response = http.request(request)
      responseBody = response.body[0,200]
    rescue Exception=>e
      responseBody = 'ERROR: OpenScape Voice validation timeout'
    end
   
    unless responseBody.include? 'TEST MODE'
    # i.e. no error, since, if there is an error, there will be 'ERROR:' instead
      
      begin
        errormessage =  responseBody[/ERROR.*$/]
        errormessage =  errormessage[7..-1]
      rescue
        errormessage =  responseBody
      end

      #record.errors[:name] << errormessage
      record.errors[' '] << errormessage
    end
  end
end



class Customer < Provisioningobject #< ActiveRecord::Base
  def new
  end
  
  def target
    Target.find(target_id) unless target_id.nil?
  end
  
  def children
    children = Site.where(customer: id).order(:name)
# better to return an empty relation instead of nil; therefore commented out:
#    if children.count > 0
#      children
#    else
#      nil
#    end
  end
  
  def parent
    target
  end
  
  def parentClass
    Target
  end
  
  def self.parentClass
    Target
  end
  
  def parentSym
    :target
  end
  
  def self.parentSym
    :target
  end
  
  def self.childClass
    Site
  end
  
  def childClass
    Site
  end
  
  def self.provisioningAction(method, myparent=nil)
     # note: myparent is not needed for customers, but the varible is needed for Sites, so for unification, a second argument is needed
     "action=List Customers"
  end
  
  def provisioningAction(method)
   
    case method
      when :create
        "action=Add Customer, customerName=#{name}, customerLanguage=#{language}"
      when :destroy
        if name.nil?
          abort "cannot de-provision customer without name"
        end
        "action=Delete Customer, customerName=#{name}"
      when :read
	#"action=List Customers"
        "action=List Customers, customerName=#{name}"
      else
        abort "Unsupported provisioning method"
    end
  end
  
  def self.xmlElements(xml_data)
    doc = REXML::Document.new(xml_data)
    myelements = doc.root.elements["GetBGListData"]
    
    myelements.each do |element|
      # skip special customer (BG) named BG_DC
          #abort myelements.class.inspect
      myelements.delete_element(element) if /\ABG_DC\Z/.match(element.text)
    end
    
    myelements.elements
  end
  
  def self.find_from_REXML_element(element, mytarget)
    self.where(name: element.text, target_id: mytarget.id)
  end
  
  def self.create_from_REXML_element(element, mytarget)
    self.new(name: element.text, target_id: mytarget.id)
  end

  if false
  def self.synchronizeAllOld(targets = nil, async=true, recursive=false)
    # now replaced by Provisioningobject.synchronizeAll

    targets ||= Target.all
    if async
      returnBody = delay.synchronizeAllSynchronously(targets, recursive)
    else
      returnBody = synchronizeAllSynchronously(targets, recursive)
    end
  end
  end

# TODO: remove after successful test on physical systems
if false
  def self.synchronizeAllSynchronouslyOld(targets, recursive=false)
    targets.each do |mytarget|
		#abort mytarget.inspect
      #responseBody = Customer::provision(:read, false, Customer, mytarget)
      #responseBody = Customer.read(mytarget)
      responseBody = self.read(mytarget)
		#abort responseBody
      # error handling:
      abort "synchronizeAllSynchronously(: ERROR: provisioningRequest timeout reached!" if responseBody.nil?

      # depending on the result, targetobject.provision can return a Fixnum. We need to convert this to a String
      responseBody = "synchronizeAllSynchronously: ERROR: #{self.class.name} does not exist" if responseBody.is_a?(Fixnum) && responseBody == 101

      # abort, if it is still a Fixnum:
      abort "synchronizeAllSynchronously: ERROR: wrong responseBody type (#{responseBody.class.name}) instead of String)" unless responseBody.is_a?(String)
      # business logic error:
      abort "received an ERROR response for provision(:read) in synchronizeAllSynchronously" unless responseBody[/ERROR.*$/].nil?
    
      require 'rexml/document'
      xml_data = responseBody
      doc = REXML::Document.new(xml_data)
      
            #abort doc.root.elements["GetBGListData"].elements.inspect
      doc.root.elements["GetBGListData"].elements.each do |element|
		        #abort element.text.inspect
        # skip special customer (BG) named BG_DC
        next if /\ABG_DC\Z/.match( element.text )
        # skip if the customer exists already in the database:
		        #abort xml_data.inspect
		        #abort element.text.inspect
        #next if Customer.where(name: element.text).count > 0
        #next if Customer.where(name: element.text, target_id: mytarget.id).count > 0
        next if self.where(name: element.text, target_id: mytarget.id).count > 0
		        #abort element.text
  
        # found an object that is not in the DB:
        newProvisioningobject = self.new(name: element.text, target_id: mytarget.id, status: 'provisioning successful (verified existence)')
  
        # today, it is not possible to read the language etc from Camel PE, so we cannot save with validations.
        # save it with no validations. 
        newProvisioningobject.save!(validate: false)
      
		#abort newCustomer.inspect
  
	p 'SSSSSSSSSSSSSSSSSSSSSSSSS    Customer.synchronizeAll responseBody    SSSSSSSSSSSSSSSSSSSSSSSSS'
        p responseBody.inspect
      end # doc.root.elements["GetBGListData"].elements.each do |element|
    end # targets.each do |target|
  end
  
end

 
    # see http://rails-bestpractices.com/posts/708-clever-enums-in-rails
    LANGUAGES = [LANGUAGE_ENGLISH_US = 'englishUS', LANGUAGE_ENGLISH_GB = 'englishGB', LANGUAGE_GERMAN = 'german'] # spanish, frensh, italian, portuguesePT, portugueseBR, dutch, russian, turkish

    belongs_to :target
    has_many :sites, dependent: :destroy
    has_many :provisionings
    
    validates :language, inclusion: {in: LANGUAGES}
    #validates :name, unique_on_target: {:case_sensitive => false, :myclass => self.inspect.gsub(/\(.*/,'')}
    validates :name, presence: true,
                     #uniqueness: true, 
                     uniqueness: {:case_sensitive => false},
                     length: { in: 3..20  }
    validates_format_of :name, :with => /\A[A-Z,a-z,0-9,_]{0,100}\Z/, message: "needs to consist of 3 to 20 characters: A-Z, a-z, 0-9 and/or _"
    validates :target_id, presence: true
    
#    validates_with ValidateWithProvisioningEngine
#    validates_with ValidateLanguage
#    handle_asynchronously :create_on_OSV
end


