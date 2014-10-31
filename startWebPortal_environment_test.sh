export HTTP_PROXY=
export http_proxy=

~/.rbenv/shims/rails s -e test -p 80 >> /var/log/WebPortal_environment_test.log &
  sleep 1
  myWebPortalPid=`ps -ef | grep "rails s" | grep -v grep | grep -v shims | awk '{print $2}'`
  echo "Web Portal started: PID=$myWebPortalPid"
  echo "Web Portal started: PID=$myWebPortalPid" >> /var/log/WebPortal.log
