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
        when /PrepareSystem/
          alreadyProvisioned = true
          case alreadyProvisioned
            when true # case alreadyProvisioned
              responseBody = '<pre>###################################
# OSV_VR
###################################
###################################
# OSV_VR
###################################
Allow SSH password authentication (needed by Apache Camel SSH module) ...&quot; &amp;&amp; grep -q &quot;PasswordAuthentication no&quot; /etc/ssh/sshd_config &amp;&amp; appendix=.camel.bak_`date +%F--%s` &amp;&amp; cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config$appendix &amp;&amp; sed &quot;s/PasswordAuthentication no/PasswordAuthentication yes/&quot; /etc/ssh/sshd_config$appendix &gt; /etc/ssh/sshd_config &amp;&amp; /etc/init.d/sshd restart &amp;&amp; echo &quot;PrepareOSVSSH: added password authentication support...&quot; || echo &quot;PrepareOSVSSH: password authentication is already supported: nothing to do...&quot; )
whoami | grep -q Preparing srx access from the ProvisioningEngine...&quot; &amp;&amp; grep &quot;\-\:srx&quot; /etc/security/access.conf | grep  -v -q &quot;192.168.113.104&quot; &amp;&amp; appendix=.camel.bak_`date +%F--%s` &amp;&amp; cp -p /etc/security/access.conf /etc/security/access.conf$appendix &amp;&amp; sed &quot;s/\(\-\:srx.*LOCAL\)/\1 192.168.113.104 /&quot; /etc/security/access.conf$appendix &gt; /etc/security/access.conf &amp;&amp; echo &quot;PrepareOSVSSH: added Web Portal to the list of allowed srx ssh hosts&quot; || echo &quot;PrepareOSVSSH: Web Portal already allowed: nothing to do&quot; )
whoami | grep 
###################################
# OSV_VR
###################################
version of existing ProvisioningScripts = 0.4.7.2
version of new ProvisioningScripts = 0.4.7.2
Existing ProvisioningScripts do not need to be upgraded. Exiting...

###################################
# OSV_VR
###################################
running batch file...
headers.batchFileName = batchFile-31607548.sh
sh batchFile-31607548.sh &gt; batchFile-31607548.sh.out
Nothing to do: Packet Filter Rule &quot;SOAP_permit_192.168.113.104&quot; exists already
Nothing to do: Packet Filter Rule &quot;SPML_permit_192.168.113.104&quot; exists already
finished execution of batch file batchFile-31607548.sh

###################################
# OSV_VR
###################################

###################################
# OSV_VR
###################################


###################################
# XPR_V7: XPR Provisioning not supported for action=PrepareSystem
###################################

###################################
# UC_V: UC Provisioning not supported for action=PrepareSystem
###################################

</pre>'
            when false # case alreadyProvisioned
              responseBody ='<pre>###################################
# OSV_VR
###################################
###################################
# OSV_VR
###################################
Allow SSH password authentication (needed by Apache Camel SSH module) ...&quot; &amp;&amp; grep -q &quot;PasswordAuthentication no&quot; /etc/ssh/sshd_config &amp;&amp; appendix=.camel.bak_`date +%F--%s` &amp;&amp; cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config$appendix &amp;&amp; sed &quot;s/PasswordAuthentication no/PasswordAuthentication yes/&quot; /etc/ssh/sshd_config$appendix &gt; /etc/ssh/sshd_config &amp;&amp; /etc/init.d/sshd restart &amp;&amp; echo &quot;PrepareOSVSSH: added password authentication support...&quot; || echo &quot;PrepareOSVSSH: password authentication is already supported: nothing to do...&quot; )
whoami | grep -q Preparing srx access from the ProvisioningEngine...&quot; &amp;&amp; grep &quot;\-\:srx&quot; /etc/security/access.conf | grep  -v -q &quot;192.168.113.104&quot; &amp;&amp; appendix=.camel.bak_`date +%F--%s` &amp;&amp; cp -p /etc/security/access.conf /etc/security/access.conf$appendix &amp;&amp; sed &quot;s/\(\-\:srx.*LOCAL\)/\1 192.168.113.104 /&quot; /etc/security/access.conf$appendix &gt; /etc/security/access.conf &amp;&amp; echo &quot;PrepareOSVSSH: added Web Portal to the list of allowed srx ssh hosts&quot; || echo &quot;PrepareOSVSSH: Web Portal already allowed: nothing to do&quot; )
whoami | grep 
###################################
# OSV_VR
###################################
folder ProvisioningScripts does not exist yet. It will be created now.
version of new ProvisioningScripts = 0.4.7.2
found new ProvisioningScripts version: starting to extract ProvisioningScripts.tar.gz, overwriting existing files...
ProvisioningScripts/
ProvisioningScripts/ccc.sh
ProvisioningScripts/ccc_variables_examples.txt
ProvisioningScripts/chsettings.sh
ProvisioningScripts/delete.awk
ProvisioningScripts/delete.sh
ProvisioningScripts/delete_variables.txt
ProvisioningScripts/export.sh
ProvisioningScripts/findAndReplaceTools
ProvisioningScripts/modules/
ProvisioningScripts/modules/ccc_MI_Feature_01_ServiceCodeXprUC.sh
ProvisioningScripts/modules/ccc_MI_Fixes_01_CQ00270348_Alias.sh
ProvisioningScripts/modules/ccc_MI_Fixes_02_DeleteIntercepts.sh
ProvisioningScripts/modules/ccc_MT_Base_01_DeletedCommands.sh
ProvisioningScripts/modules/ccc_MT_Base_02_Renaming.sh
ProvisioningScripts/modules/ccc_MT_Base_03_UCMediaserver.sh
ProvisioningScripts/modules/ccc_MT_Base_04_Xpressions.sh
ProvisioningScripts/modules/ccc_MT_Base_05_CentralGateway.sh
ProvisioningScripts/modules/ccc_MT_Base_06_DNM.sh
ProvisioningScripts/modules/ccc_MT_Base_07_OfficeCode.sh
ProvisioningScripts/modules/ccc_MT_Base_08_RemainingChanges.sh
ProvisioningScripts/modules/ccc_MT_Feature_01_ServiceCodeXprUC.sh
ProvisioningScripts/modules/ccc_MT_Fixes_01_DeltaProblems.sh
ProvisioningScripts/modules/ccc_MT_FI_01_DeletedCommands.sh
ProvisioningScripts/modules/ccc_MT_FI_02_Renaming.sh
ProvisioningScripts/modules/ccc_MT_FI_03_UCMediaserver.sh
ProvisioningScripts/modules/ccc_MT_FI_04_Xpressions.sh
ProvisioningScripts/modules/ccc_MT_FI_05_CentralGateway.sh
ProvisioningScripts/modules/ccc_MT_FI_06_OSVMediaserver.sh
ProvisioningScripts/modules/ccc_MT_FI_07_APAC_DestCode.sh
ProvisioningScripts/modules/ccc_MT_FI_Fixes_01_DeleteIntercepts.sh
ProvisioningScripts/modules/exec_MT_FI/
ProvisioningScripts/modules/exec_MT_FI/S011_ccc_MT_FI_01_DeletedCommands
ProvisioningScripts/modules/exec_MT_FI/S012_ccc_MT_FI_02_Renaming
ProvisioningScripts/modules/exec_MT_FI/S013_ccc_MT_FI_03_UCMediaserver
ProvisioningScripts/modules/exec_MT_FI/S014_ccc_MT_FI_04_Xpressions
ProvisioningScripts/modules/exec_MT_FI/S015_ccc_MT_FI_05_CentralGateway
ProvisioningScripts/modules/exec_MT_FI/S016_ccc_MT_FI_06_DNM
ProvisioningScripts/modules/exec_MT_FI/S017_ccc_MT_FI_07_OSVMediaserver
ProvisioningScripts/modules/exec_MT_FI/S018_ccc_MT_FI_08_APAC_DestCode
ProvisioningScripts/modules/exec_MT/
ProvisioningScripts/modules/exec_MT/S011_ccc_MT_Base_01_DeletedCommands
ProvisioningScripts/modules/exec_MT/S012_ccc_MT_Base_02_Renaming
ProvisioningScripts/modules/exec_MT/S013_ccc_MT_Base_03_UCMediaserver
ProvisioningScripts/modules/exec_MT/S014_ccc_MT_Base_04_Xpressions
ProvisioningScripts/modules/exec_MT/S015_ccc_MT_Base_05_CentralGateway
ProvisioningScripts/modules/exec_MT/S016_ccc_MT_Base_06_DNM
ProvisioningScripts/modules/exec_MT/S017_ccc_MT_Base_07_OfficeCode
ProvisioningScripts/modules/exec_MT/S018_ccc_MT_Base_08_RemainingChanges
ProvisioningScripts/modules/exec_MT/S051_ccc_MT_Feature_01_ServiceCodeXprUC
ProvisioningScripts/modules/exec_MT/S101_ccc_MT_Fixes_01_DeltaProblems
ProvisioningScripts/modules/exec_MT/S102_ccc_MT_Fixes_02_DNM_CQ00305443
ProvisioningScripts/modules/exec_MT/S000_ccc_all_00_DeleteFeatureProfiles.sh
ProvisioningScripts/modules/exec_MI/
ProvisioningScripts/modules/exec_MI/S051_ccc_MI_Feature_01_ServiceCodeXprUC
ProvisioningScripts/modules/exec_MI/S101_ccc_MI_Fixes_01_CQ00270348_Alias
ProvisioningScripts/modules/exec_MI/S102_ccc_MI_Fixes_02_DeleteIntercepts
ProvisioningScripts/modules/ccc_MT_Base_00_DeleteFeatureProfiles.sh
ProvisioningScripts/modules/ccc_all_00_DeleteFeatureProfiles.sh
ProvisioningScripts/modules/ccc_MT_FI_06_DNM.sh
ProvisioningScripts/modules/ccc_MT_FI_07_OSVMediaserver.sh
ProvisioningScripts/modules/ccc_MT_FI_08_APAC_DestCode.sh
ProvisioningScripts/modules/ccc_MT_FI_Fixes_01_DeleteIntercepts_obsolete_inV8.sh
ProvisioningScripts/modules/ccc_MT_Fixes_02_DNM_CQ00305443.sh
ProvisioningScripts/removelinebreaks.sh
ProvisioningScripts/soapCli/
ProvisioningScripts/soapCli/myCancelJob
ProvisioningScripts/soapCli/mySoapRequest
ProvisioningScripts/soapCli/myTestProcessXml
ProvisioningScripts/soapCli/soapCommon.ksh
ProvisioningScripts/soapCli/soapCli
ProvisioningScripts/soapCli/TestSendSoapReq
ProvisioningScripts/soapCli/TestSoap.ksh
ProvisioningScripts/soapCli/xml.templates
ProvisioningScripts/soapCli/TestSendSoapReq.orig
ProvisioningScripts/split_bg.awk
ProvisioningScripts/split_site.awk
ProvisioningScripts/version.txt
ProvisioningScripts/export_all.sh
ProvisioningScripts/split_feature.awk
ProvisioningScripts/FirstInitialisationOSVTemplate_V7.txt
ProvisioningScripts/FirstInitialisationOSVTemplate_V8.txt
ProvisioningScripts/soapMassProv.sh
ProvisioningScripts/openscapevoiceconfig_V8_wo_HomeDn_display_and_BGLINENAME_corrected.txt
backup.sh
restore.sh
ProvisioningScripts successfully updated

###################################
# OSV_VR
###################################
running batch file...
headers.batchFileName = batchFile-80083641.sh
sh batchFile-80083641.sh &gt; batchFile-80083641.sh.out
Packet Filter Rule &quot;SOAP_permit_192.168.113.104&quot; created. For removing, log into the OSV Linux prompt and perform su - srx -c &quot;startCli -x&quot; and then pktFltrRulesRemove &quot;SOAP_permit_192.168.113.104&quot;
Packet Filter Rule &quot;SPML_permit_192.168.113.104&quot; created. For removing, log into the OSV Linux prompt and perform su - srx -c &quot;startCli -x&quot; and then pktFltrRulesRemove &quot;SPML_permit_192.168.113.104&quot;
finished execution of batch file batchFile-80083641.sh

###################################
# OSV_VR
###################################

###################################
# OSV_VR
###################################


###################################
# XPR_V7: XPR Provisioning not supported for action=PrepareSystem
###################################

###################################
# UC_V: UC Provisioning not supported for action=PrepareSystem
###################################

</pre>'
            when 'mixed' # case alreadyProvisioned
			# from a test with OSV V7R1, where may be the Password authentication was correct or no; need to retest the Password authentication part in Camel...
              responseBody ='###################################
# OSV_VR
###################################
###################################
# OSV_VR
###################################
Allow SSH password authentication (needed by Apache Camel SSH module) ..." && grep -q "PasswordAuthentication no" /etc/ssh/sshd_config && appendix=.camel.bak_`date +%F--%s` && cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config$appendix && sed "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config$appendix > /etc/ssh/sshd_config && /etc/init.d/sshd restart && echo "PrepareOSVSSH: added password authentication support..." || echo "PrepareOSVSSH: password authentication is already supported: nothing to do..." )
whoami | grep -q Preparing srx access from the ProvisioningEngine..." && grep "\-\:srx" /etc/security/access.conf | grep  -v -q "192.168.113.104" && appendix=.camel.bak_`date +%F--%s` && cp -p /etc/security/access.conf /etc/security/access.conf$appendix && sed "s/\(\-\:srx.*LOCAL\)/\1 192.168.113.104 /" /etc/security/access.conf$appendix > /etc/security/access.conf && echo "PrepareOSVSSH: added Web Portal to the list of allowed srx ssh hosts" || echo "PrepareOSVSSH: Web Portal already allowed: nothing to do" )
whoami | grep 
###################################
# OSV_VR
###################################
version of existing ProvisioningScripts = 0.4.7.2
version of new ProvisioningScripts = 0.4.7.2
Existing ProvisioningScripts do not need to be upgraded. Exiting...

###################################
# OSV_VR
###################################
running batch file...
headers.batchFileName = batchFile-93733174.sh
sh batchFile-93733174.sh > batchFile-93733174.sh.out
Nothing to do: Packet Filter Rule "SOAP_permit_192.168.113.104" exists already
Nothing to do: Packet Filter Rule "SPML_permit_192.168.113.104" exists already
finished execution of batch file batchFile-93733174.sh

###################################
# OSV_VR
###################################

###################################
# OSV_VR
###################################


###################################
# XPR_V7: XPR Provisioning not supported for action=PrepareSystem
###################################

###################################
# UC_V: UC Provisioning not supported for action=PrepareSystem
###################################'
          end # case alreadyProvisioned
        else # case headerHash["action"]
          responseBody = "HttpPostRequest.perform: action=#{headerHash["action"]} not supported in simulation mode"
      end # case headerHash["action"]
    else # if simulationMode   
      begin
        response = http.request(request)
        responseBody = response.body
      rescue
        responseBody = nil
      end
    end # else # if simulationMode

    #flash[:notice]  = "Received answer: #{responesBody.to_s}"
  
    
    return responseBody
  end # def perform
end
