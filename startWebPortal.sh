export HTTP_PROXY=
export http_proxy=
[ -w /var/log/WebPortal.log ] || ( sudo touch /var/log/WebPortal.log; sudo chown provisioningengine:provisioningengine /var/log/WebPortal.log  )

~/.rbenv/shims/rails s -p 3000 >> /var/log/WebPortal.log &
  sleep 2
  myWebPortalPid=`ps -ef | grep "rails s" | grep -v grep | grep -v shims | awk '{print $2}'`
  echo "Web Portal started: PID=$myWebPortalPid"
  echo "Web Portal started: PID=$myWebPortalPid" >> /var/log/WebPortal.log
