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



class Customer < ActiveRecord::Base
  def new
  end
  
  def activeJob?
    # will return true, if the object has an active job
    
    @provisionings = Provisioning.where(customer: self)
    
    # search for active jobs:
    @provisionings.each do |provisioning|    
      return true if provisioning.activeJob?
    end
    
    # else return false:
    return false
  end
  
  def provisioned?
    if /provisioning successful/.match(status)
      true
    else
      false
    end
  end
  
  def provision(inputBody, async=true)

    @customer = Customer.find(id)
    # e.g. inputBody = "action = Add Customer, customerName=#{name}" 
    
    unless @customer.target_id.nil?
      @target = Target.find(@customer.target_id)
      actionAppend = @target.configuration.gsub(/\n/, ', ')
      actionAppend = actionAppend.gsub(/\r/, '')
    end
    
    # recursive deletion of sites (skipped in test mode):
    if inputBody.include?("Delete") && !inputBody.include?("testMode")
      @sites = Site.where(customer: id)
      @sites.each do |site|
        inputBodySite = "action=Delete Site, customerName=#{@customer.name}, SiteName=#{site.name}"
        inputBodySite = inputBodySite + ', ' + actionAppend unless actionAppend.nil?
        site.provision(inputBodySite, async)
      end 
    end
    
    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?

    @provisioning = Provisioning.new(action: inputBody, customer: @customer)
    
    if @provisioning.save
       #@provisioning.createdelayedjob
       #@provisioning.deliver
       if async == true
         @provisioning.deliverasynchronously
       else
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
  
  
    has_many :sites, dependent: :destroy
    has_many :provisionings
    
    validates :name, presence: true,
                     #uniqueness: true, 
                     uniqueness: {:case_sensitive => false},
                     length: { in: 3..20  }
    validates :target_id, presence: true
    
#    validates_with ValidateWithProvisioningEngine
#    handle_asynchronously :create_on_OSV
end


