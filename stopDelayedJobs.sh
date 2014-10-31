myDelayedJobsPid=`ps -ef | grep "rake jobs:work" | grep -v grep | grep -v shims | awk '{print $2}'`

echo myDelayedJobsPid=$myDelayedJobsPid

if [ "_$myDelayedJobsPid" != "_" ]; then
  kill $myDelayedJobsPid
  echo "kill signal sent for Delayed Jobs (PID=$myDelayedJobsPid)"
  echo "kill signal sent for Delayed Jobs (PID=$myDelayedJobsPid)" >> /var/log/WebPortal.log
else
  echo "no Delayed Jobs process found"
  echo "no Delayed Jobs process found" >> /var/log/WebPortal.log
fi
