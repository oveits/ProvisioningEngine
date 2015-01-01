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
    children = Site.where(customer: id)
    if children.count > 0
      children
    else
      nil
    end
  end
  
  def provisioningAction(method)
   
    if name.nil?
      abort "cannot de-provision customer without name"
    end
    
    case method
      when :create
        "action=Add Customer, customerName=#{name}, customerLanguage=#{language}"
      when :destroy
        "action=Delete Customer, customerName=#{name}"
      else
        abort "Unsupported provisioning method"
    end
  end

# TODO: remove after successful test  
# def provisionOld(inputBody, async=true)
#
#    @customer = Customer.find(id)
#    # e.g. inputBody = "action = Add Customer, customerName=#{name}" 
#    
#    unless @customer.target_id.nil?
#      @target = Target.find(@customer.target_id)
#      actionAppend = @target.configuration.gsub(/\n/, ', ')
#      actionAppend = actionAppend.gsub(/\r/, '')
#    end
#    
#    # recursive deletion of sites (skipped in test mode):
#    if inputBody.include?("Delete") && !inputBody.include?("testMode")
#      @sites = Site.where(customer: id)
#      @sites.each do |site|
#        inputBodySite = "action=Delete Site, customerName=#{@customer.name}, SiteName=#{site.name}"
#        inputBodySite = inputBodySite + ', ' + actionAppend unless actionAppend.nil?
#        site.provision(inputBodySite, async)
#      end 
#    end
#    
#    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?
#
#    @provisioning = Provisioning.new(action: inputBody, customer: @customer)
#    
#    if @provisioning.save
#       #@provisioning.createdelayedjob
#       #@provisioning.deliver
#       if async == true
#         @provisioning.deliverasynchronously
#       else
#         @provisioning.deliver
#       end
#       # success
#       #return 0
#    else
#      @provisioning.errors.full_messages.each do |message|
#        abort 'provisioning error: ' + message.to_s
#      end
#    end 
#  end # def
  
    # see http://rails-bestpractices.com/posts/708-clever-enums-in-rails
    LANGUAGES = [LANGUAGE_ENGLISH_US = 'englishUS', LANGUAGE_ENGLISH_GB = 'englishGB', LANGUAGE_GERMAN = 'german'] # spanish, frensh, italian, portuguesePT, portugueseBR, dutch, russian, turkish

  
    has_many :sites, dependent: :destroy
    has_many :provisionings
    
    validates :language, inclusion: {in: LANGUAGES}
    #validates :name, unique_on_target: {:case_sensitive => false, :myclass => self.inspect.gsub(/\(.*/,'')}
    validates :name, presence: true,
                     #uniqueness: true, 
                     uniqueness: {:case_sensitive => false},
                     length: { in: 3..20  }
    validates_format_of :name, :with => /\A[A-Z,a-z,0-9,_]{1,100}+\Z/, message: "Customer Name contains invalid characters: Customer Name needs to consist of 1 to 21 characters: A-Z, a-z, 0-9 and/or _"
    validates :target_id, presence: true
    
#    validates_with ValidateWithProvisioningEngine
#    validates_with ValidateLanguage
#    handle_asynchronously :create_on_OSV
end


