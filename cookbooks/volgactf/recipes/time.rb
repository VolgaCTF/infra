timezone 'UTC' do
  action :set
end

template '/etc/systemd/timesyncd.conf' do
  source 'systemd/timesyncd.conf.erb'
  variables(
    ntp: node['timesyncd']['ntp'],
    fallback_ntp: node['timesyncd']['fallback_ntp']
  )
  action :create
end

execute 'timedatectl set-ntp true' do
  action :run
end

service 'systemd-timesyncd.service' do
  action [:enable, :start]
  subscribes :restart , 'template[/etc/systemd/timesyncd.conf]'
end
