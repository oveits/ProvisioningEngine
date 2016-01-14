export HTTP_PROXY=
export http_proxy=

[ -w /var/log/WebPortal.log ] || ( sudo touch /var/log/WebPortal.log; sudo chown provisioningengine:provisioningengine /var/log/WebPortal.log  )

cd `dirname $0`
./status | grep "Delayed Jobs: running" || ~/.rbenv/shims/rake jobs:work 
sleep 2
myDelayedJobsPid=`ps -ef | grep "rake jobs:work" | grep -v grep | grep -v shims | awk '{print $2}'`
echo "Delayed Jobs started: PID=$myDelayedJobsPid"
echo "Delayed Jobs started: PID=$myDelayedJobsPid" >> /var/log/WebPortal.log 2>&1
