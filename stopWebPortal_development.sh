myWebPortalPid=`ps -ef | grep "rails s -p 3001" | grep -v grep | grep -v shims | awk '{print $2}'`


echo myWebPortalPid=$myWebPortalPid

if [ "_$myWebPortalPid" != "_" ]; then
  kill $myWebPortalPid
  echo "kill signal sent for Web Portal (PID=$myWebPortalPid)"
  echo "kill signal sent for Web Portal (PID=$myWebPortalPid)" >> /var/log/WebPortal.log
else
  echo "no Web Portal process found"
  echo "no Web Portal process found" >> /var/log/WebPortal.log
fi
