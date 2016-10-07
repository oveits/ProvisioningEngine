#!/usr/bin/env bash

export HTTP_PROXY=
export http_proxy=

[ -w /var/log/WebPortal.log ] || ( sudo touch /var/log/WebPortal.log; sudo chown provisioningengine:provisioningengine /var/log/WebPortal.log  )

myDelayedJobsPid=`ps -ef | grep "rake jobs:work" | grep -v grep | grep -v shims | awk '{print $2}'`
[ "$myDelayedJobsPid" == "" ] && ~/.rbenv/shims/rake jobs:work | tee -a /var/log/WebPortal.log 2>&1 &
sleep 2
myDelayedJobsPid=`ps -ef | grep "rake jobs:work" | grep -v grep | grep -v shims | awk '{print $2}'`
if [ "$myDelayedJobsPid" != "" ]; then
  echo "Delayed Jobs started: PID=$myDelayedJobsPid"
  echo "Delayed Jobs started: PID=$myDelayedJobsPid" >> /var/log/WebPortal.log 2>&1
else
  message="Could not start Delayed Jobs! See /var/log/WebPortal.log for details."
  echo "$message" >> /var/log/WebPortal.log 2>&1
  echo "$message" >&2
  exit 1
fi
