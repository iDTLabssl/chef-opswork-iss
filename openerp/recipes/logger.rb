include_recipe "openerp"
include_recipe 'sumologic'

sumo_source 'syslog' do
  path '/var/log/syslog'
  category 'syslog'
end

sumo_source 'dmesg' do
  path '/var/log/dmesg '
  category 'dmesg'
end

sumo_source 'messages' do
  path '/var/log/messages'
  category 'messages'
end

sumo_source 'secure' do
  path '/var/log/secure'
  category 'secure'
end

sumo_source 'nginx-access' do
  path '/etc/nginx/logs/access.log'
  category 'nginx-access'
end

sumo_source 'nginx-error' do
  path '/etc/nginx/logs/error.log'
  category 'nginx-error'
end

sumo_source 'openerp' do
  path '/srv/www/idt_software_services/shared/log/openerp.log'
  category 'openerp'
end

sumo_source 'auth' do
  path '/var/log/auth.log'
  category 'auth'
end

sumo_source 'kern' do
  path '/var/log/kern.log'
  category 'kern'
end

sumo_source 'cron' do
  path '/var/log/cron.log'
  category 'cron'
end

sumo_source 'mail' do
  path '/var/log/mail.log'
  category 'mail'
end

sumo_source 'boot' do
  path '/var/log/boot.log'
  category 'boot'
end

sumo_source 'wtmp' do
  path 'var/log/wtmp'
  category 'wtmp'
end

