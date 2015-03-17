./startDelayedJobs_development.sh >> /var/log/WebPortal.log 2>&1 &
  sleep 2
  myDelayedJobsPid=`ps -ef | grep "startDelayedJobs_development.sh" | grep -v grep | grep -v shims | awk '{print $2}'`
  echo "Delayed Jobs started: PID=$myDelayedJobsPid"
  echo "Delayed Jobs started: PID=$myDelayedJobsPid" >> /var/log/WebPortal.log 2>&1
