default[:openerp][:apt_packages] = %w[
  libssl-dev
  libsasl2-dev
  libldap2-dev
  libxml2-dev 
  libxslt1-dev
  libjpeg-dev
  libjpeg8-dev
  graphviz
  libevent-dev
  ghostscript
  poppler-utils
  libxext6
  fontconfig
  python-pypdf
  python-reportlab
  python-yaml
  python-ldap
  python-pil
  nodejs
  npm
  python-cups
  libfontenc1 
  libxfont1  
  xfonts-75dpi 
  xfonts-base 
  xfonts-encodings 
  xfonts-utils
  unzip
  zip
  postgresql-client-9.4
]

default[:openerp][:pip_packages] = %w[
  raven
  raven-sanitize-openerp
  phonenumbers
  wkhtmltopdf
  subprocess32
  boto  
  oauthlib
  egenix-mx-base
  filechunkio
]
  
#default[:openerp][:database][:name] = node[:opsworks][:stack][:rds_instances][:db_name]
#default[:openerp][:database][:host] = node[:opsworks][:stack][:address]
#default[:openerp][:database][:password] = ''
#default[:openerp][:database][:port] = node[:opsworks][:stack][:port]
#default[:openerp][:database][:user] = node[:opsworks][:stack][:db_user]
default[:openerp][:database][:maxconn] = 30
default[:openerp][:servername] = 'servername'

default[:openerp][:nginx_authuser] = 'user'
default[:openerp][:nginx_authpass] = 'pass'

default[:openerp][:data_dir] = '/mnt/data'
default[:openerp][:db_filter] = '%h'
default[:openerp][:debug_mode] = 'False'
default[:openerp][:email_from] = 'no-reply@iss.sl'

default[:openerp][:admin_pass] = 'supersecret'
default[:openerp][:addons_path] = 'openerp/addons/'
default[:openerp][:sentry_dsn] = 'secret'
default[:openerp][:aws_access_key] = 'secret'
default[:openerp][:aws_secret_key] = 'secret'
default[:openerp][:route53_zone_id] = ''
default[:openerp][:domain] = ''
default[:openerp][:workers] = 3
default[:openerp][:elastic_ip] = ''
default[:openerp][:log_handler] = "[':WARNING']"
default[:openerp][:log_level] = 'info'
default[:openerp][:static_http_document_root] = '/var/www/'
default[:openerp][:static_http_url_prefix]= '/static'
default[:openerp][:openoffice_deb_url]  = 'http://freefr.dl.sourceforge.net/project/openofficeorg.mirror/4.1.1/binaries/en-US/Apache_OpenOffice_4.1.1_Linux_x86-64_install-deb_en-US.tar.gz'
default[:openerp][:wkhtmltopdf_deb_url]  = "http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb"

default[:openerp][:update_command] = ''
default[:openerp][:ssl_public] = '/etc/nginx/ssh/server.crt'
default[:openerp][:ssl_private] = '/etc/nginx/ssh/server.pem'


override['supervisor']['inet_port'] = '9001'

override['nginx']['worker_processes'] = 4
override['nginx']['default_site_enabled'] = false
override['nginx']['gzip'] = 'on'


override['postgresql']['enable_pgdg_apt'] = true 
override['postgresql']['version'] = '9.3'
override[:chef_ec2_ebs_snapshot][:description] = "saas.sl data directory Backup $(date +'%Y-%m-%d %H:%M:%S')"



#set the ff in stack settings
# node['supervisor']['inet_username']
# node['supervisor']['inet_password']
#
#
#
#
#
#
#


