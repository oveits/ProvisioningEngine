#!/usr/bin/env bash

export HTTP_PROXY=
export http_proxy=

# detect current user and group
WHOAMI=`whoami`
GROUP=`groups | awk '{print $1}'`

# detect, whether we need sudo:
sudo echo hallo 2>/dev/null 1>/dev/null && SUDO=sudo

# prepare log file:
[ -d /var/log ] || $SUDO mkdir -p /var/log
[ -w /var/log/WebPortal.log ] || ( $SUDO touch /var/log/WebPortal.log; $SUDO chown ${WHOAMI}:${GROUP} /var/log/WebPortal.log  )

# detect, whether WebPortal is running on port 3000:
myWebPortalPid=`ps -ef | grep "rails s" | grep "3000" | grep -v grep | grep -v shims | awk '{print $2}'`

# start Web Portal, if not running:
[ "$myWebPortalPid" == "" ] && ~/.rbenv/shims/rails s -p 3000 >> /var/log/WebPortal.log 2>&1 &
                                #~/.rbenv/shims/rails s -e 'production' -p 3000
sleep 2
# detect PID:
myWebPortalPid=`ps -ef | grep "rails s" | grep "3000" | grep -v grep | grep -v shims | awk '{print $2}'`

if [ "$myWebPortalPid" != "" ]; then
  message="Web Portal started: PID=$myWebPortalPid"
  echo "$message" >> /var/log/WebPortal.log 2>&1
  echo "$message" >&2
  exit 0
else
  message="Could not start Web Portal! See /var/log/WebPortal.log for details."
  echo "$message" >> /var/log/WebPortal.log 2>&1
  echo "$message" >&2
  exit 1
fi

