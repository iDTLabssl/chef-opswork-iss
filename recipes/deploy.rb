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

Chef::Log.info "About to search apps"

# Search apps to be deployed. Without deploy:true filter all apps would be returned.
apps = search(:aws_opsworks_app, "deploy:true") rescue []
Chef::Log.info "Found #{apps.size} apps to deploy on the stack. Assuming they are all Odoo apps."

instance = search("aws_opsworks_instance", "self:true").first
Chef::Log.info("********** For instance '#{instance['instance_id']}', the instance's hostname is '#{instance['hostname']}' **********")

rds_db_instance = search("aws_opsworks_rds_db_instance").first
Chef::Log.info("********** The RDS instance's address is '#{rds_db_instance['address']}' **********")

apps.each do |app|
  
  if app["shortname"] != instance['hostname'] then
       Chef::Log.warn("********** Skipping because we can not deploy '#{app['shortname']}' on instance '#{instance['hostname']}' **********")
       next
  end

  app_path = ::File.join('/srv', app["shortname"])
  Chef::Log.info "Deploying #{app["shortname"]} to #{app_path}."

  app_source = app["app_source"]

  # deploy git repo from opsworks app
  application app_path do
    owner node[:deploy_user][:user]
    group node[:deploy_user][:group]
    git app_path do
      repository       app_source["url"]
      revision         app_source["revision"]
      deploy_key       app_source["ssh_key"]
    end
  end

  # create data dir if for some reason its not there
  directory node[:openerp][:data_dir] do
    owner node[:deploy_user][:user]
    group node[:deploy_user][:group]
    mode 00755
    action :create
    not_if { ::File.exists?(node[:openerp][:data_dir]) }
  end

  # create static web directory its not there
  directory '/var/www' do
    owner node[:deploy_user][:user]
    group node[:deploy_user][:group]
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
    command "chown {node[:deploy_user][:user]}:{node[:deploy_user][:group]} {node[:openerp][:data_dir]}; chmod 775 {node[:openerp][:data_dir]}"
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
    cwd app_path
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
    cwd app_path
    code <<-EOH
    npm install -g less less-plugin-clean-css
    EOH
  end

  script 'chmod_gevent' do
    interpreter "bash"
    user "root"
    cwd app_path
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

  template "/home/#{node[:deploy_user][:user]}/.openerp_serverrc" do
    source "openerp.conf.erb"
    owner node[:deploy_user][:user]
    group node[:deploy_user][:group]
    mode "0644"
    action :create
    variables(
      :deploy_path => app_path,
      :log_file =>  "/var/logs/#{app["shortname"]}.log",
      :pid_file =>  "/var/run/#{app["shortname"]}.pid",
      :database => rds_db_instance
    ) 
  end

  supervisor_service "openerp" do
    command "python ./odoo.py"
    directory app_path
    user node[:deploy_user][:user]
    autostart true
    autorestart true
    environment :HOME => "/home/#{node[:deploy_user][:user]}",:PYTHON_EGG_CACHE => "/tmp/python-eggs",:PYTHONPATH => "/usr/local/lib/python2.7/dist-packages:/usr/local/lib/python2.7/site-packages"
  end

  supervisor_service "openerp" do
    action :stop
  end


#  script 'execute_db_update' do
#    interpreter "bash"
#    user node[:deploy_user][:user]
#    cwd app_path
#    environment 'HOME' => "/home/#{node[:deploy_user][:user]}"
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
    owner node[:deploy_user][:user]
    group node[:deploy_user][:group]
    mode 00755
    action :create
  end
  template "/etc/nginx/.htpasswd" do
        source "htpasswd.erb"
      end

  template "/etc/nginx/default_ssl.crt" do
        source "server.crt.erb"
        variables({
          :ssl_crt => app['ssl_configuration']['certificate'],
	        :ssl_crt_ca => app['ssl_configuration']['chain'],
        })
      end
      
    template "/etc/nginx/default_ssl.key" do
        source "server.pem.erb"
        variables({
          :ssl_pem => app['ssl_configuration']['private_key'],
        })
      end

  

  template "/etc/nginx/sites-available/#{node[:openerp][:servername]}.conf" do
    source "nginx-openerp.conf.erb"
    variables({
      :deploy_path => app_path,
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


