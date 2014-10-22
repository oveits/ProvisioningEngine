export HTTP_PROXY=
export http_proxy=

~/.rbenv/shims/rake jobs:work >> /var/log/WebPortal.log &
  myDelayedJobsPid=`ps -ef | grep "rake jobs:work" | grep -v grep | grep -v shims | awk '{print $2}'`
  echo "Delayed Jobs started: PID=$myDelayedJobsPid"
  echo "Delayed Jobs started: PID=$myDelayedJobsPid" >> /var/log/WebPortal.log
