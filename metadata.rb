name             'openerp'
maintainer       'iDT Labs'
maintainer_email 'salton.massally@gmail.com'
license           "Apache 2.0"
description      'Installs/Configures openerp-server on opswork ... assumes you already have a database running... we use rds'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "ohai"
depends "supervisor"
depends "nginx"
depends "postgresql"
depends "java"
depends "idt_infra_tools"
depends 'tar'
depends 'sumologic-collector'



%w{ ubuntu }.each do |os|
  supports os
end
