class ValidateWithProvisioningEngine < ActiveModel::Validator
  def validate(record)
    require "net/http"
    require "uri"
    
    uri = URI.parse("http://localhost/CloudWebPortal")
    
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
  def create_on_OSV(name)
    #send the newsletter here, which will take some time and you
    #sleep(15)
    #p '-----------------------------------------------------------'
    #puts 'From send newsletter: ' + name
    #p '-----------------------------------------------------------'
    #sleep 100
    #abort '--------------------test---------------------------'
    require "net/http"
    require "uri"
    
    uri = URI.parse("http://localhost/CloudWebPortal")
    
    #response = Net::HTTP.post_form(uri, {"testMode" => "testMode", "offlineMode" => "offlineMode", "action" => "Add Customer", "customerName" => @customer.name})
    #OV replaced by (since I want to control the timers):
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 2
    http.read_timeout = 500
    request = Net::HTTP::Post.new(uri.request_uri)
    #request.set_form_data({"testMode" => "testMode", "action" => "Add Customer", "customerName" => name})
    request.set_form_data({"action" => "Add Customer", "customerName" => name})
    
    begin
      response = http.request(request)
      #responseBody = response.body[0,200]
      responseBody = response.body
    rescue Exception=>e
      responseBody = 'ERROR: OpenScape Voice provisioning timeout'
    end
    
    

#    p '#########################################################################################'
#    p 'responseBody = ' + responseBody
#    p '#########################################################################################'    
#    
#    begin
#      errormessage =  responseBody[/ERROR.*$/]
#      errormessage =  errormessage[7..-1]
#    rescue
#      errormessage =  responseBody
#    end
#    
#      p '#########################################################################################'
#    unless errormessage.nil?
#      p 'error message = ' + errormessage
#    else
#      p 'error message = nil'
#    end
#      p '#########################################################################################'
       
    #unless responseBody[/Warnings:0    Errors:0     Syntax Errors:0/]
    unless responseBody[/Warnings:0    Errors/]
      #record.errors[:name] << errormessage
      #record.errors[' '] << errormessage  
      begin
        errormessage = responseBody[/ERROR.*$/]
        errormessage =  errormessage[7..-1]  
      rescue
        begin
          errormessage = "Import errors: " + responseBody[/OSV.*$/]
        rescue
          errormessage responseBody[0,200]
        end
      end
      
        
#      begin
#        abort errormessage
#      rescue
#        begin
#          abort responseBody[/OSV.*$/]
#        rescue
#          abort responseBody
#        end
#      end
      #abort "test"
      errors[:name] << errormessage
      errors[' '] << errormessage
        # for debugging:
        p responseBody[0,200]
      #abort errormessage
    end
     
  end
    
  def provision(inputBody)
    @customer = Customer.find(id)
    # e.g. inputBody = "action = Add Customer, customerName=#{name}" 
    
    unless @customer.target_id.nil?
      @target = Target.find(@customer.target_id)
      actionAppend = @target.configuration.gsub(/\n/, ', ')
      actionAppend = actionAppend.gsub(/\r/, '')
    end
    
    # recursive deletion of sites:
    @sites = Site.where(customer: id)
    @sites.each do |site|
      inputBodySite = "action=Delete Site, customerName=#{@customer.name}, SiteName=#{site.name}"
      inputBodySite = inputBodySite + ', ' + actionAppend unless actionAppend.nil?
      site.provision(inputBodySite)
    end
    
    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?

    @provisioning = Provisioning.new(action: inputBody, customer: @customer)
    
    if @provisioning.save
       #@provisioning.createdelayedjob
       #@provisioning.deliver
       @provisioning.deliverasynchronously
       # success
       return 0
    else
      @provisioning.errors.full_messages.each do |message|
        abort 'provisioning error: ' + message.to_s
      end
    end 
  end # def
  
  
    has_many :sites, dependent: :destroy
    has_many :provisionings
    validates :name, presence: true,
                     uniqueness: true, 
                     length: { in: 3..20  }
    validates :target_id, presence: true
#    validates_with ValidateWithProvisioningEngine
#    handle_asynchronously :create_on_OSV
end


