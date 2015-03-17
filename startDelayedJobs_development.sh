export HTTP_PROXY=
export http_proxy=

[ -w /var/log/WebPortal.log ] || ( sudo touch /var/log/WebPortal.log; sudo chown provisioningengine:provisioningengine /var/log/WebPortal.log  )

~/.rbenv/shims/rake jobs:work
