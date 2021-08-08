# frozen_string_literal: true

if node['netdata']['enabled']
  %w[autoconf autoconf-archive autogen automake cmake curl gcc git gzip libelf-dev libjson-c-dev libjudy-dev liblz4-dev libmnl-dev libssl-dev libtool libuv1-dev make netcat pkg-config python3 tar uuid-dev zlib1g-dev].each do |pkg_name|
    package pkg_name
  end

  netdata_install 'default' do
    install_method 'source'
    git_repository node['netdata']['git_repository']
    git_revision node['netdata']['git_revision']
    git_source_directory '/opt/netdata'
    autoupdate false
    update node['netdata']['update']
  end

  netdata_global_conf = {
    'memory mode' => 'dbengine',
    'page cache size' => node['netdata']['global']['page cache size'],
    'dbengine multihost disk space' => node['netdata']['global']['dbengine multihost disk space']
  }

  unless node['netdata']['global']['hostname'].nil?
    netdata_global_conf['hostname'] = node['netdata']['global']['hostname']
  end

  netdata_global_conf['bind to'] = node['netdata']['global']['bind to'] unless node['netdata']['global']['bind to'].nil?

  netdata_config 'global' do
    owner 'netdata'
    group 'netdata'
    configurations netdata_global_conf
  end

  netdata_registry_conf = {
    'enabled' => node['netdata']['registry']['enabled'] ? 'yes' : 'no',
    'registry to announce' => node['netdata']['registry']['registry to announce']
  }

  unless node['netdata']['registry']['registry hostname'].nil?
    netdata_registry_conf['registry hostname'] = node['netdata']['registry']['registry hostname']
  end

  netdata_config 'registry' do
    owner 'netdata'
    group 'netdata'
    configurations netdata_registry_conf
  end

  unless node['netdata']['global']['hostname'].nil?
    tls_vlt = ::Vlt::Client.new(::Vlt.file_auth_provider, 'tls')
    tls_vlt_provider = -> { tls_vlt }

    tls = ::ChefCookbook::TLS.new(node, vlt_provider: tls_vlt_provider, vlt_format: 2)

    if tls.has_ec_certificate?(node['netdata']['global']['hostname'])
      tls_ec_certificate node['netdata']['global']['hostname'] do
        owner 'netdata'
        group 'netdata'
        vlt_provider tls_vlt_provider
        vlt_format 2
        action :deploy
      end

      certificate_entry = tls.ec_certificate_entry(node['netdata']['global']['hostname'])

      netdata_config 'web' do
        owner 'netdata'
        group 'netdata'
        configurations(lazy do
          {
            'tls version' => '1.3',
            '# ssl certificate checksum' => certificate_entry.certificate_checksum,
            'ssl certificate' => certificate_entry.certificate_path,
            '# ssl key checksum' => certificate_entry.certificate_private_key_checksum,
            'ssl key' => certificate_entry.certificate_private_key_path
          }
        end)
      end
    end
  end

  service 'netdata' do
    action :nothing
  end

  file '/var/lib/netdata/cloud.d/cloud.conf' do
    owner 'netdata'
    group 'netdata'
    content "[global]\n  enabled = no"
    mode mode '0644'
    action :create
    notifies :restart, 'service[netdata]', :delayed
  end

  vlt = ::Vlt::Client.new(::Vlt.file_auth_provider)

  template '/etc/netdata/health_alarm_notify.conf' do
    source 'netdata/health_alarm_notify.conf.erb'
    owner 'netdata'
    group 'netdata'
    mode 0o644
    variables(lazy do
      {
        send_telegram: node['netdata']['health_alarm_notify']['telegram']['enabled'],
        telegram_bot_token: node['netdata']['health_alarm_notify']['telegram']['enabled'] ? vlt.read(node['netdata']['health_alarm_notify']['telegram']['credential'], prefix: 'telegram', key: 'bot_token') : '',
        default_recipient_telegram: node['netdata']['health_alarm_notify']['telegram']['enabled'] ? vlt.read(node['netdata']['health_alarm_notify']['telegram']['credential'], prefix: 'telegram', key: 'chat_id') : ''
      }
    end)
    action :create
    notifies :restart, 'service[netdata]', :delayed
  end
end
