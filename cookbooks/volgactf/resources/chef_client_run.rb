resource_name :chef_client_run

default_action :setup

property :name, String, name_property: true

property :on_calendar, String, default: ''
property :randomized_delay_sec, String, default: ''

action :setup do
  systemd_unit 'chef-client.service' do
    content(
      Unit: {
        Description: 'Run chef-client',
        Wants: 'chef-client.timer',
        OnFailure: 'unit-status-telegram@%n.service'
      },
      Service: {
        ExecStart: '/usr/bin/chef-client -l warn'
      },
      Install: {
        WantedBy: 'multi-user.target'
      }
    )
    action :create
  end

  systemd_unit 'chef-client.timer' do
    content(
      Unit: {
        Description: 'Run chef-client daily',
        Requires: 'chef-client.service'
      },
      Timer: {
        Unit: 'chef-client.service',
        OnCalendar: new_resource.on_calendar,
        RandomizedDelaySec: new_resource.randomized_delay_sec,
        AccuracySec: '1s'
      },
      Install: {
        WantedBy: 'timers.target'
      }
    )
    action [:create, :enable, :start]
  end
end

action :uninstall do
  systemd_unit 'chef-client.timer' do
    action [:stop, :disable, :delete]
  end

  systemd_unit 'chef-client.service' do
    action :delete
  end
end
