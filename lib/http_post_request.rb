class HttpPostRequest
  def perform(action, uriString=ENV["PROVISIONINGENGINE_CAMEL_URL"], httpreadtimeout=4*3600, httpopentimeout=6)
    #
    # renders action="param1=value1, param2=value2, ..." and sends a HTTP POST request to uriString (default: "http://localhost/CloudWebPortal")
    #
    
    if ENV["WEBPORTAL_SIMULATION_MODE"] == "true"
      simulationMode = true
    else 
      simulationMode = false
    end

    require "net/http"
    require "uri"
    
    uri = URI.parse(uriString)
    
    #response = Net::HTTP.post_form(uri, {"testMode" => "testMode", "offlineMode" => "offlineMode", "action" => "Add Customer", "customerName" => @customer.name})
    #OV replaced by (since I want to control the timers):
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = httpopentimeout
    http.read_timeout = httpreadtimeout
    request = Net::HTTP::Post.new(uri.request_uri)
    #requestviatyphoeus = Typhoeus::Request.new("http://localhost/CloudWebPortal")

    array = action.split(/,/) #.map(&:strip) #seems to lead sporadically to action=Show Sites to be converted to 'Show Sites' => '' instead of 'action' => 'Show Sites' during Site synchronization
#    p '+++++++++++++++++++++++++  action.split(/,/) ++++++++++++++++++++++++++++++++'
#    p array.inspect
#    p array.map(&:strip).inspect
    
    #array = array.map(&:strip)
    
    postData = {}

    while array[0]
      variableValuePairArray = array.shift.split(/=/).map(&:strip)
#      p '+++++++++++++++++++++++++  variableValuePairArray ++++++++++++++++++++++++++++++++'
#      p variableValuePairArray.inspect
      if variableValuePairArray.length.to_s[/^2$/]
        postData[variableValuePairArray[0]] = variableValuePairArray[1]
      elsif variableValuePairArray.length.to_s[/^1$/]
        postData[variableValuePairArray[0]] = ""
      else
        abort "action (here: #{action}) must be of the format \"variable1=value1,variable2=value2, ...\""
      end
    end
  
    if simulationMode
      simulationLogString = "(simlulated) "
    else
      simulationLogString = ""
    end


    p "------------- HttpPostRequest POST Data to #{uriString} #{simulationLogString}-----------------"
    p postData.inspect
    p '----------------------------------------------------------'

    request.set_form_data(postData)

    # flash does not work in this environment:
    #flash[:notice]  = "Sent HTTP POST Data to #{uriString} #{simulationLogString}"

    if simulationMode
      sleep 15.seconds
      responseBody = "Success: 234     Errors:0     Syntax Errors:0"
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
