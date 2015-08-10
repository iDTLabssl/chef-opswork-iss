#
# Cookbook Name:: openerp
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe "supervisor"
include_recipe "nginx::repo"
include_recipe "nginx"
include_recipe "nginx::http_stub_status_module"
include_recipe "python"
include_recipe 'java'
include_recipe 'postgresql::client'

# lets set the python egg cache
directory "/tmp/python-eggs" do
  owner "root"
  group "root"
  mode 00777
  action :create
end

magic_shell_environment 'PYTHON_EGG_CACHE' do
  value '/tmp/python-eggs'
end

magic_shell_environment 'PYTHONPATH' do
  value '/usr/local/lib/python2.7/dist-packages:/usr/local/lib/python2.7/site-packages'
end

magic_shell_environment 'UNO_PATH' do
  value '/opt/openoffice4/program/'
end



node[:openerp][:apt_packages].each do |pkg|
  package pkg do
    action :install
  end
end

  
# lets ensure that pillow has jpeg support
  bash "correct_for_pillow" do
    code <<-EOH
    ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib
    ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib
    ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib
    EOH
    not_if { ::File.exists?('/usr/lib/libjpeg.so') }
  end
  
# lets install openoffice

directory "#{Chef::Config[:file_cache_path]}/openoffice" do
  recursive true
end

tar_extract node['openerp']['openoffice_deb_url'] do
  target_dir "#{Chef::Config[:file_cache_path]}/openoffice"
  not_if { File.directory?("#{Chef::Config[:file_cache_path]}/openoffice/en-US") }
end

execute 'install-openoffice-debs' do
  command "dpkg -i #{Chef::Config[:file_cache_path]}/openoffice/en-US/DEBS/*.deb"
  not_if 'dpkg -s openoffice'
end

bash "link_openoffice" do
    code <<-EOH
    ln -s /opt/openoffice4/program/soffice /usr/bin
    EOH
    not_if { ::File.exists?('/usr/bin/soffice') }
  end

  
# lets setup unoconv
git "#{Chef::Config[:file_cache_path]}/unoconv" do
  repository "https://github.com/dagwieers/unoconv.git"
  reference "master"
  action :sync
end

bash "install_unoconv_build" do
  cwd "#{Chef::Config[:file_cache_path]}/unoconv"
  code <<-EOH
    make install
  EOH
end


 supervisor_service "unoconv" do
   command "unoconv --listener"
   user 'ubuntu'
   autostart true
   autorestart true
   environment :HOME => "/home/ubuntu",:PYTHON_EGG_CACHE => "/tmp/python-eggs",:PYTHONPATH => "/usr/local/lib/python2.7/dist-packages:/usr/local/lib/python2.7/site-packages":UNO_PATH => "/opt/openoffice4/program/"
 end
