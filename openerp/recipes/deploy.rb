#
# Cookbook Name:: openerp
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#include_recipe "supervisor"
include_recipe "openerp"
#include_recipe "nginx::repo"
#include_recipe "nginx"
#include_recipe "nginx::http_stub_status_module"

include_recipe 'deploy'

node[:deploy].each do |application, deploy|
   if deploy[:application_type] != 'other'
     Chef::Log.debug("Skipping deploy::other application #{application} as it is not an other app")
     next
   end

  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  opsworks_deploy do
    deploy_data deploy
    app application
  end

  # create data dir if for some reason its not there
  directory node[:openerp][:data_dir] do
    owner deploy[:user]
    group deploy[:group]
    mode 00755
    action :create
    not_if { ::File.exists?(node[:openerp][:data_dir]) }
  end

  # create static web directory its not there
  directory '/var/www' do
    owner deploy[:user]
    group deploy[:group]
    mode 00755
    action :create
  end
  
  
#  bash "fix_setuptools" do
#      code <<-EOH
#      easy_install -U setuptools
#      EOH
#    end

# lets ensure that the data dir is writable
  bash "correct_directory_permission" do
    command "chown {deploy[:user]}:{deploy[:group]} {node[:openerp][:data_dir]}; chmod 775 {node[:openerp][:data_dir]}"
    only_if { ::File.exists?(node[:openerp][:data_dir]) }
  end

  node[:openerp][:pip_packages].each do |pkg|
    python_pip pkg do
      action :install
    end
  end

  service 'nginx' do
    supports :status => true, :restart => true, :reload => true
  end

  script 'install_requirements' do
    interpreter "bash"
    user "root"
    cwd deploy[:absolute_document_root]
    code "pip install -r requirements.txt"
  end

  bash "correct_node_link" do
    code <<-EOH
    ln -s /usr/bin/nodejs /usr/bin/node
    EOH
    not_if { ::File.exists?('/usr/bin/node') }
  end

  script 'install_less' do
    interpreter "bash"
    user "root"
    cwd deploy[:absolute_document_root]
    code <<-EOH
    npm install -g less less-plugin-clean-css
    EOH
  end

  script 'chmod_gevent' do
    interpreter "bash"
    user "root"
    cwd deploy[:absolute_document_root]
    code "chmod +x openerp-gevent"
  end

# lets bring back sanity
#  bash "fix_packages" do
#    cwd '/tmp'
#    code <<-EOH
#    wget http://python-distribute.org/distribute_setup.py
#    python distribute_setup.py
#    EOH
#  end

  template "/home/#{deploy[:user]}/.openerp_serverrc" do
    source "openerp.conf.erb"
    owner deploy[:user]
    group deploy[:group]
    mode "0644"
    action :create
    variables(
      :deploy_path => deploy[:absolute_document_root],
      :log_file =>  "#{deploy[:deploy_to]}/shared/log/openerp.log",
      :pid_file =>  "#{deploy[:deploy_to]}/shared/pids/openerp.pid",
      :database => deploy[:database]
    ) 
  end

  supervisor_service "openerp" do
    command "python ./odoo.py"
    directory deploy[:absolute_document_root]
    user deploy[:user]
    autostart true
    autorestart true
    environment :HOME => "/home/#{deploy[:user]}",:PYTHON_EGG_CACHE => "/tmp/python-eggs",:PYTHONPATH => "/usr/local/lib/python2.7/dist-packages:/usr/local/lib/python2.7/site-packages"
  end

  supervisor_service "openerp" do
    action :stop
  end


#  script 'execute_db_update' do
#    interpreter "bash"
#    user deploy[:user]
#    cwd deploy[:absolute_document_root]
#    environment 'HOME' => "/home/#{deploy[:user]}"
#    code "python db_update.py --backup_dir=#{node[:openerp][:data_dir]}/backups/"
#    notifies :restart, "supervisor_service[openerp]"
#  end

  # let's configure nginx
  bash "install_h5bp" do
    code <<-EOH
     rm -R /etc/nginx
     EOH
  end
  remote_directory '/etc/nginx' do
    source 'nginx'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end
	# nginx log directory
  directory '/etc/nginx/logs/' do
    owner deploy[:user]
    group deploy[:group]
    mode 00755
    action :create
  end
  template "/etc/nginx/.htpasswd" do
        source "htpasswd.erb"
      end

  template "/etc/nginx/default_ssl.crt" do
        source "server.crt.erb"
        variables({
          :ssl_crt => deploy[:ssl_certificate],
	  :ssl_crt_ca => deploy[:ssl_certificate_ca],
        })
      end
      
    template "/etc/nginx/default_ssl.key" do
        source "server.pem.erb"
        variables({
          :ssl_pem => deploy[:ssl_certificate_key],
        })
      end

  

  template "/etc/nginx/sites-available/#{node[:openerp][:servername]}.conf" do
    source "nginx-openerp.conf.erb"
    variables({
      :deploy_path => deploy[:absolute_document_root],
    })
    notifies :reload, "service[nginx]"
  end
   
    nginx_site "#{node[:openerp][:servername]}.conf" do
    enable true
  end

  # let's get some of our statics in place
  directory node[:openerp][:static_http_document_root] do
    owner node[:openerp][:user]
    group node[:openerp][:group]
    mode 00755
    action :create
    not_if { ::File.exists?(node[:openerp][:static_http_document_root]) }
  end
  remote_directory "#{node[:openerp][:static_http_document_root]}404" do
    source '404'
    owner node[:openerp][:user]
    group node[:openerp][:group]
    mode '0755'
    action :create
  end
  
  supervisor_service "openerp" do
      action :start
    end
 

end


