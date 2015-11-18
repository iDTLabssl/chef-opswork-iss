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
include_recipe 'postgresql::apt_pgdg_postgresql'
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
  

# lets install wkhtmltopdf

remote_file "#{Chef::Config[:file_cache_path]}/wkhtmltox.deb" do
  source node['openerp']['wkhtmltopdf_deb_url']
  mode 0644
#  checksum "" # PUT THE SHA256 CHECKSUM HERE
end

dpkg_package "wkhtmltopdf" do
  source "#{Chef::Config[:file_cache_path]}/wkhtmltox.deb"
  action :install
end

bash "link_wkhtmltopdf" do
    code <<-EOH
    cp /usr/local/bin/wkhtmltopdf /usr/bin
    cp /usr/local/bin/wkhtmltoimage /usr/bin
    EOH
    not_if { ::File.exists?('/usr/bin/wkhtmltopdf') }
  end

# install some necessary missing fonts
remote_file "#{Chef::Config[:file_cache_path]}/pfbfer.zip" do
  source 'http://www.reportlab.com/ftp/fonts/pfbfer.zip'
  mode 0644
end

directory '/usr/lib/python2.7/dist-packages/reportlab/fonts/' do
    mode 00755
    action :create
    not_if { ::File.exists?('/usr/lib/python2.7/dist-packages/reportlab/fonts/') }
  end

bash "unzip_fonts" do
    code <<-EOH
    unzip -o #{Chef::Config[:file_cache_path]}/pfbfer.zip -d /usr/lib/python2.7/dist-packages/reportlab/fonts/
    EOH
  end
  
