class HttpPostRequest
  def perform(headerInput, uriString=ENV["PROVISIONINGENGINE_CAMEL_URL"], httpreadtimeout=4*3600, httpopentimeout=6)
    #
    # renders headerInput="param1=value1, param2=value2, ..." and sends a HTTP POST request to uriString (default: "http://localhost/CloudWebPortal")
    #
    
    if ENV["WEBPORTAL_SIMULATION_MODE"] == "true"
      simulationMode = true
    else 
      simulationMode = false
    end

    require "net/http"
    require "uri"
    
    uri = URI.parse(uriString)
    
    #response = Net::HTTP.post_form(uri, {"testMode" => "testMode", "offlineMode" => "offlineMode", "headerInput" => "Add Customer", "customerName" => @customer.name})
    #OV replaced by (since I want to control the timers):
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = httpopentimeout
    http.read_timeout = httpreadtimeout
    request = Net::HTTP::Post.new(uri.request_uri)
    #requestviatyphoeus = Typhoeus::Request.new("http://localhost/CloudWebPortal")

    array = headerInput.split(/,/) #.map(&:strip) #seems to lead sporadically to headerInput=Show Sites to be converted to 'Show Sites' => '' instead of 'action' => 'Show Sites' during Site synchronization
#    p '+++++++++++++++++++++++++  headerInput.split(/,/) ++++++++++++++++++++++++++++++++'
#    p array.inspect
#    p array.map(&:strip).inspect
    
    #array = array.map(&:strip)
    
    headerHash = {}

#abort headerInput.match(/\A([^=\n]+=[^=,\n]+)([,\n]*[^=,\n]+=[^=,\n]+)*\Z/).inspect
#abort headerInput.is_a?(String).inspect
#abort (!!headerInput.match(/\A([^=\n]+=[^=,\n]+)([,\n]*[^=,\n]+=[^=,\n]+)*\Z/)).inspect
    
    if headerInput.is_a?(Hash)
      headerHash = headerInput
    #elsif headerInput.is_a?(String) && headerInput.match(/\A([^=\n]+=[^=,\n]+)([,\n]*[^=,\n]+=[^=,\n]+)*\Z/)
    elsif headerInput.is_a?(String) && headerInput.match(/\A([^=\n]+=[^=,\n]*)([,\n]*[^=,\n]+=[^=,\n]*)*\Z/)
  
      while array[0]
        variableValuePairArray = array.shift.split(/=/).map(&:strip)
  #      p '+++++++++++++++++++++++++  variableValuePairArray ++++++++++++++++++++++++++++++++'
  #      p variableValuePairArray.inspect
        if variableValuePairArray.length.to_s[/^2$/]
          headerHash[variableValuePairArray[0]] = variableValuePairArray[1]
        elsif variableValuePairArray.length.to_s[/^1$/]
          headerHash[variableValuePairArray[0]] = ""
        else
          abort "headerInput (here: #{headerInput}) must be of the format \"variable1=value1,variable2=value2, ...\""
        end
      end
    else
      abort "HttpPostRequest: wrong headerInput (#{headerInput.inspect}) type or format"
    end # if headerInput.is_a?(Hash)

    if simulationMode
      simulationLogString = "(simlulated) "
    else
      simulationLogString = ""
    end


    p "------------- HttpPostRequest POST Data to #{uriString} #{simulationLogString}-----------------"
    p headerHash.inspect
    p '----------------------------------------------------------'

    request.set_form_data(headerHash)

    # flash does not work in this environment:
    #flash[:notice]  = "Sent HTTP POST Data to #{uriString} #{simulationLogString}"

    if simulationMode
          begin
            # if not initialized, the following line will fail:
            @@customerprovisioned.nil?
          rescue
            # and the variable will be initialized
            @@customerprovisioned = nil
          end
          begin
            # if not initialized, the following line will fail:
            @@siteprovisioned.nil?
          rescue
            # and the variable will be initialized
            @@siteprovisioned = nil
          end
          begin
            # if not initialized, the following line will fail:
            @@userprovisioned.nil?
          rescue
            # and the variable will be initialized
            @@userprovisioned = nil
          end
 
      sleep 100.seconds / 1000
      case headerHash["action"]
        when /Add Customer/
          if @@customerprovisioned.nil?
            responseBody = "Success: 234     Errors:0     Syntax Errors:0"
            @@customerprovisioned = true
          else 
            @@customerprovisioned = true
            responseBody = 'ERROR: java.lang.Exception: Cannot Create customer ExampleCustomerV8: Customer exists already!'
          end
        when /Add Site/
          p "Before Add Site: @@siteprovisioned = #{@@siteprovisioned.inspect}"
          if @@siteprovisioned.nil?
            responseBody = "Success: 234     Errors:0     Syntax Errors:0"
            @@siteprovisioned = true
          else
            @@siteprovisioned = true
            responseBody = 'ERROR: java.lang.Exception: Site Name "ExampleSite" exists already in the data base (Numbering Plan = NP_Site1_00010)!'
          end
          p "After Add Site: @@siteprovisioned = #{@@siteprovisioned.inspect}"
        when /Add User/
          if @@userprovisioned.nil?
            responseBody = "Success: 234     Errors:0     Syntax Errors:0"
            @@userprovisioned = true
          else
            @@userprovisioned = true
            responseBody = 'ERROR: java.lang.Exception: Cannot create user with phone number +49 (99) 7007 30800: phone number is in use already!'
          end
        when /Delete Customer/
          if @@customerprovisioned == true
            responseBody = "Success: 234     Errors:0     Syntax Errors:0"
            @@customerprovisioned = nil
          else
            responseBody = 'ERROR: java.lang.Exception: Customer "ExampleCustomerV8" does not exist on the data base!'
            @@customerprovisioned = nil
          end
        when /Delete Site/
          p "Before Delete Site: @@siteprovisioned = #{@@siteprovisioned.inspect}"
          if @@siteprovisioned == true
            responseBody = "Success: 234     Errors:0     Syntax Errors:0"
            @@siteprovisioned = nil
          else
            responseBody = 'ERROR: java.lang.Exception: Site Name "ExampleSite" does not exist in the data base!'
            @@siteprovisioned = nil
          end
          p "After Delete Site: @@siteprovisioned = #{@@siteprovisioned.inspect}"
        when /Delete User/
          if @@userprovisioned == true
            responseBody = "Success: 234     Errors:0     Syntax Errors:0"
            @@userprovisioned = nil
          else
            responseBody = 'ERROR: java.lang.Exception: Cannot delete user with phone number +49 (99) 7007 30800: phone number does not exist for this customer!'
            @@userprovisioned = nil
          end
        when /Show Sites/
		#p "@@siteprovisioned is #{@@siteprovisioned.inspect}"
		#p "Before Show Sites: @@siteprovisioned = #{@@siteprovisioned.inspect}"
          if @@siteprovisioned == true
            responseBody = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<Result>
    <ResultCode>0</ResultCode>
    <ResultText>Success</ResultText>
    <Sites>
        <Site>
            <CustomerName>ExampleCustomerV8</CustomerName>
            <SiteName>ExampleCustomerV8</SiteName>
            <NumberingPlanName>CNP_ExampleCustomerV8_00007</NumberingPlanName>
            <GatewayIP></GatewayIP>
            <MainNumber></MainNumber>
        </Site>
        <Site>
            <CustomerName>ExampleCustomerV8</CustomerName>
            <SiteName>ExampleSite</SiteName>
            <NumberingPlanName>NP_ExampleSite_00008</NumberingPlanName>
            <GatewayIP>47.68.190.57</GatewayIP>
            <SiteCode>99821</SiteCode>
            <CountryCode>49</CountryCode>
            <AreaCode>99</AreaCode>
            <LocalOfficeCode>7007</LocalOfficeCode>
            <ExtensionLength>5</ExtensionLength>
            <MainNumber>4999700710000</MainNumber>
        </Site>
    </Sites>
</Result>'
            else
              responseBody = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<Result>
    <ResultCode>0</ResultCode>
    <ResultText>Success</ResultText>
    <Sites>
        <Site>
            <SiteName>ExampleCustomerV8</SiteName>
            <NumberingPlanName>CNP_ExampleCustomerV8_00013</NumberingPlanName>
            <GatewayIP></GatewayIP>
            <MainNumber></MainNumber>
        </Site>
    </Sites>
</Result>'
            end
        when /List Users/
          if @@userprovisioned == true
            responseBody = '<Result><ServiceId>4999700730800</ServiceId><ServiceId>9999999991</ServiceId><ServiceId>9999999992</ServiceId></Result>'
          else
            responseBody = '<Result><ServiceId>9999999991</ServiceId><ServiceId>9999999992</ServiceId></Result>'
          end
        when /List Customers/
		#p "Before List Customers: @@customerprovisioned = #{@@customerprovisioned.inspect}"
          if @@customerprovisioned == true
            responseBody = '<?xml version="1.0" encoding="UTF-8"?>
<SOAPResult><Result>Success</Result><GetBGListData><BGName>BG_DC</BGName><BGName>Thomas1</BGName><BGName>OllisTestCustomer</BGName><BGName>ExampleCustomerV8</BGName><BGName>OllisTestCustomer2</BGName><BGName>ExampleCustomer</BGName></GetBGListData></SOAPResult>'
          else
            responseBody = '<?xml version="1.0" encoding="UTF-8"?>
<SOAPResult><Result>Success</Result><GetBGListData><BGName>BG_DC</BGName><BGName>Thomas1</BGName><BGName>OllisTestCustomer</BGName><BGName>OllisTestCustomer2</BGName></GetBGListData></SOAPResult>'
          end
        else
          responseBody = "action not supported in simulation mode: have received #{headerHash["action"]}"
      end
    else    
      begin
        response = http.request(request)
        responseBody = response.body
      rescue
        responseBody = nil
      end
    end

    #flash[:notice]  = "Received answer: #{responesBody.to_s}"
  
    
    return responseBody
  end # def perform
end
