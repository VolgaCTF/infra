resource_name :unit_status_telegram_service

default_action :setup

property :name, String, name_property: true
property :telegram_bot_token, String, default: ''
property :telegram_chat_id, String, default: ''
property :conf_dir, String, default: '/etc/unit-status-telegram'

action :setup do
  directory new_resource.conf_dir do
    owner 'root'
    group node['root_group']
    mode 0o700
    recursive true
    action :create
  end

  conf_file = ::File.join(new_resource.conf_dir, 'defaults')

  template conf_file do
    cookbook 'volgactf'
    source 'unit-status-telegram/defaults.erb'
    owner 'root'
    group node['root_group']
    variables(
      telegram_bot_token: new_resource.telegram_bot_token,
      telegram_chat_id: new_resource.telegram_chat_id
    )
    sensitive true
    action :create
  end

  run_file = '/usr/bin/unit-status-telegram'

  cookbook_file run_file do
    cookbook 'volgactf'
    source 'unit-status-telegram/run.sh'
    owner 'root'
    group node['root_group']
    mode 0o755
    action :create
  end

  systemd_unit 'unit-status-telegram@.service' do
    content(
      Unit: {
        Description: 'Unit Status Telegram Service',
        After: 'network.target'
      },
      Service: {
        Type: 'simple',
        EnvironmentFile: conf_file,
        ExecStart: "#{run_file} %i"
      }
    )
    action :create
  end
end

action :uninstall do
  systemd_unit 'unit-status-telegram@.service' do
    action :delete
  end

  file '/usr/bin/unit-status-telegram' do
    action :delete
  end

  file ::File.join(new_resource.conf_dir, 'defaults') do
    action :delete
  end

  directory new_resource.conf_dir do
    action :delete
  end
end
