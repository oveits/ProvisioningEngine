#!/usr/bin/env bash

export HTTP_PROXY=
export http_proxy=
[ -w /var/log/WebPortal.log ] || ( sudo touch /var/log/WebPortal.log; sudo chown provisioningengine:provisioningengine /var/log/WebPortal.log  )

  myWebPortalPid=`ps -ef | grep "rails s" | grep "3000" | grep -v grep | grep -v shims | awk '{print $2}'`
  [ "$myWebPortalPid" == "" ] && ~/.rbenv/shims/rails s -p 3000 >> /var/log/WebPortal.log 2>&1 &
                                #~/.rbenv/shims/rails s -e 'production' -p 3000
  sleep 2
  myWebPortalPid=`ps -ef | grep "rails s" | grep "3000" | grep -v grep | grep -v shims | awk '{print $2}'`

if [ "$myWebPortalPid" != "" ]; then
  echo "Web Portal started: PID=$myWebPortalPid"
  echo "Web Portal started: PID=$myWebPortalPid" >> /var/log/WebPortal.log 2>&1
else
  message="Could not start Web Portal! See /var/log/WebPortal.log for details."
  echo "$message" >> /var/log/WebPortal.log 2>&1
  echo "$message" >&2
  exit 1
fi

