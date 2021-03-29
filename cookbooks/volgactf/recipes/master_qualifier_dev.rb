node.default['firewall']['iptables']['defaults'][:ruleset] = {
  '*filter' => 1,
  ":INPUT DROP" => 2,
  ":FORWARD DROP" => 3,
  ":OUTPUT ACCEPT" => 4,
  'COMMIT_FILTER' => 100
}

firewall 'default' do
  ipv6_enabled node['firewall']['ipv6_enabled']
  action :install
end

firewall_rule 'related,established' do
  stateful [:related, :established]
  protocol :none
  command :allow
end

firewall_rule 'loopback' do
  interface 'lo'
  protocol :none
  command :allow
end

firewall_rule 'icmp' do
  protocol :icmp
  source '0.0.0.0/0'
  command :allow
end

if node['firewall']['ipv6_enabled']
  firewall_rule 'icmpv6' do
    protocol :'ipv6-icmp'
    command :allow
  end
end

firewall_rule 'ssh' do
  stateful :new
  protocol :tcp
  port node['volgactf']['ssh_port']
end

firewall_rule 'wireguard' do
  stateful :new
  protocol :udp
  source '0.0.0.0/0'
  port node['volgactf']['wireguard_port']
  command :allow
end

ngx_http_ssl_module 'default' do
  openssl_version node['openssl']['version']
  openssl_checksum node['openssl']['checksum']
  action :add
end

ngx_http_v2_module 'default'
ngx_http_stub_status_module 'default'
ngx_http_realip_module 'default'
ngx_http_gzip_static_module 'default'
ngx_brotli_module 'default'
ngx_http_geoip2_module 'default'

dhparam_file 'default' do
  key_length node['dhparam']['default_key_size']
  action :create
end

nginx_install 'default' do
  version node['ngx']['version']
  checksum node['ngx']['checksum']
  with_threads false
  with_debug false
  directives(
    main: {
      worker_processes: 'auto',
      worker_rlimit_nofile: 100 * 1024
    },
    events: {
      worker_connections: 4096,
      multi_accept: 'on'
    },
    http: {
      server_tokens: 'off',
      sendfile: 'on',
      tcp_nopush: 'on',
      tcp_nodelay: 'on',
      keepalive_requests: 1024,
      keepalive_timeout: 256
    }
  )
  action :run
end

user_ulimit 'set filehandle ulimits for nginx' do
  username lazy { node.run_state['nginx']['user'] }
  filehandle_soft_limit 8 * 100 * 1024
  filehandle_hard_limit 8 * 100 * 1024 + 8192
end

nginx_conf 'gzip' do
  cookbook 'volgactf'
  template 'nginx/gzip.conf.erb'
  action :create
end

nginx_conf 'resolver' do
  cookbook 'volgactf'
  template 'nginx/resolver.conf.erb'
  variables(
    resolvers: %w[1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4],
    resolver_valid: 600,
    resolver_timeout: 10
  )
  action :create
end

nginx_conf 'ssl' do
  cookbook 'ngx-modules'
  template 'ssl.conf.erb'
  variables(lazy {
    {
      ssl_dhparam: ::ChefCookbook::DHParam.file(node, 'default'),
      ssl_configuration: 'intermediate'
    }
  })
  action :create
end

ngx_realip_from = ['127.0.0.1']
if node['volgactf']['qualifier']['proxied'] && !node['volgactf']['qualifier']['proxy_source'].nil?
  ngx_realip_from << node['volgactf']['qualifier']['proxy_source']
end

nginx_conf 'realip' do
  cookbook 'volgactf'
  template 'nginx/realip.conf.erb'
  variables lazy {
    {
      header: 'X-Forwarded-For',
      from: ngx_realip_from
    }
  }
  action :create
end

stub_status_host = '127.0.0.1'
stub_status_port = 8099
stub_status_path = '/stub_status'

nginx_vhost 'stub_status' do
  cookbook 'volgactf'
  template 'nginx/stub_status.vhost.erb'
  variables(
    host: stub_status_host,
    port: stub_status_port,
    path: stub_status_path
  )
  action :enable
end

logrotate_app 'nginx' do
  path(lazy { ::File.join(node.run_state['nginx']['log_dir'], '*.log') })
  frequency 'daily'
  rotate 30
  options %w[
    missingok
    compress
    delaycompress
    notifempty
  ]
  postrotate(lazy { "[ ! -f #{node.run_state['nginx']['pid']} ] || kill -USR1 `cat #{node.run_state['nginx']['pid']}`" })
  action :enable
end

include_recipe 'nodejs::default'

node.default['redisio']['version'] = node['redis']['version']
node.default['redisio']['servers'] = [
  {
    'name' => nil,
    'address' => [
      '127.0.0.1'
    ],
    'port' => 6379
  }
]

sysctl 'vm.overcommit_memory' do
  value 1
  action :apply
end

include_recipe 'redisio'
include_recipe 'redisio::enable'

vlt = ::Vlt::Client.new(::Vlt.file_auth_provider)

geolite2_country_database 'default' do
  license_key lazy { vlt.read('license', prefix: 'maxmind', key: 'key') }
end

geolite2_city_database 'default' do
  license_key lazy { vlt.read('license', prefix: 'maxmind', key: 'key') }
end

include_recipe 'graphicsmagick::default'
include_recipe 'graphicsmagick::devel'

postgresql_server_install 'PostgreSQL Server' do
  setup_repo true
  port node['postgres']['port']
  version node['postgres']['version']
  password lazy { vlt.read("#{node['name']}/#{node['postgres']['root_credential']}", prefix: 'postgres', key: 'password') }
  initdb_locale node['postgres']['locale']
  action [:install, :create]
end

service 'postgresql' do
  action :nothing
end

postgresql_server_conf 'PostgreSQL Config' do
  version node['postgres']['version']
  port node['postgres']['port']
  additional_config 'listen_addresses' => '127.0.0.1'
  action :modify
  notifies :restart, 'service[postgresql]', :delayed
end

postgresql_user 'volgactf qualifier user' do
  create_user lazy { vlt.read("#{node['name']}/#{node['volgactf']['qualifier']['database']['credential']}", prefix: 'postgres', key: 'user') }
  password lazy { vlt.read("#{node['name']}/#{node['volgactf']['qualifier']['database']['credential']}", prefix: 'postgres', key: 'password') }
  action :create
end

postgresql_database node['volgactf']['qualifier']['database']['name'] do
  locale node['postgres']['locale']
  owner lazy { vlt.read("#{node['name']}/#{node['volgactf']['qualifier']['database']['credential']}", prefix: 'postgres', key: 'user') }
  action :create
end

apt_repository 'git-core' do
  uri 'ppa:git-core/ppa'
  distribution node['lsb']['codename']
end

git_client 'default' do
  package_action :upgrade
  action :install
end

tls_vlt = ::Vlt::Client.new(::Vlt.file_auth_provider, 'tls')
tls_vlt_provider = lambda { tls_vlt }

include_recipe 'agit::cleanup'

%w[
  python2.7
  python-is-python2
  python3
  python3-pip
].each do |pkg_name|
  package pkg_name do
    action :install
  end
end

cronic 'default' do
  action :install
end

ssmtp 'default' do
  sender_email node['ssmtp']['sender_email']
  smtp_host node['ssmtp']['smtp_host']
  smtp_port node['ssmtp']['smtp_port']
  smtp_username lazy { vlt.read(node['ssmtp']['smtp_credential'], prefix: 'smtp', key: 'user') }
  smtp_password lazy { vlt.read(node['ssmtp']['smtp_credential'], prefix: 'smtp', key: 'password') }
  smtp_enable_starttls node['ssmtp']['smtp_enable_starttls']
  smtp_enable_ssl node['ssmtp']['smtp_enable_ssl']
  from_line_override node['ssmtp']['from_line_override']
  action :install
end

smtp_credential = node['volgactf']['qualifier']['email']['transport'] == 'smtp' && !node['volgactf']['qualifier']['smtp']['credential'].nil?
app_backup_enabled = node['volgactf']['qualifier']['backup']['enabled']
post_twitter = node['volgactf']['qualifier']['notification']['twitter']['enabled'] && !node['volgactf']['qualifier']['notification']['twitter']['credential'].nil?
post_telegram = node['volgactf']['qualifier']['notification']['telegram']['enabled'] && !node['volgactf']['qualifier']['notification']['telegram']['credential'].nil?
# telegram_socks5_enabled = post_telegram && node['volgactf']['qualifier']['notification']['telegram']['socks5']['enabled']

volgactf_qualifier_app node['volgactf']['qualifier']['fqdn'] do
  instance_user node['volgactf']['user']
  instance_user_home ::File.join('/home', node['volgactf']['user'])
  instance_group node['volgactf']['group']

  development node.chef_environment == 'development'
  optimize_delivery node['volgactf']['qualifier']['optimize_delivery']
  listen_ipv6 node['firewall']['ipv6_enabled']
  secure node['volgactf']['qualifier']['secure']
  proxied node['volgactf']['qualifier']['proxied'] && !node['volgactf']['qualifier']['proxy_source'].nil?
  ocsp_stapling node['volgactf']['qualifier']['ocsp_stapling']

  vlt_provider tls_vlt_provider

  num_processes_server node['volgactf']['qualifier']['num_processes_server']
  num_processes_queue node['volgactf']['qualifier']['num_processes_queue']

  email_transport node['volgactf']['qualifier']['email']['transport']
  email_webhook node['volgactf']['qualifier']['email']['webhook']
  email_address_validator node['volgactf']['qualifier']['email']['address_validator']
  email_address_validator_ignore_list node['volgactf']['qualifier']['email']['address_validator_ignore_list']
  email_sender_name node['volgactf']['qualifier']['email']['sender_name']
  email_sender_address node['volgactf']['qualifier']['email']['sender_address']

  customizers node['volgactf']['qualifier']['customizers']
  customizer_name node['volgactf']['qualifier']['customizer_name']

  cleanup_upload_dir_enabled node['volgactf']['qualifier']['cleanup_upload_dir']['enabled']
  cleanup_upload_dir_cron_mailto node['volgactf']['qualifier']['cleanup_upload_dir']['cron']['mailto']
  cleanup_upload_dir_cron_mailfrom node['volgactf']['qualifier']['cleanup_upload_dir']['cron']['mailfrom']
  cleanup_upload_dir_cron_minute node['volgactf']['qualifier']['cleanup_upload_dir']['cron']['minute']
  cleanup_upload_dir_cron_hour node['volgactf']['qualifier']['cleanup_upload_dir']['cron']['hour']
  cleanup_upload_dir_cron_day node['volgactf']['qualifier']['cleanup_upload_dir']['cron']['day']
  cleanup_upload_dir_cron_month node['volgactf']['qualifier']['cleanup_upload_dir']['cron']['month']
  cleanup_upload_dir_cron_weekday node['volgactf']['qualifier']['cleanup_upload_dir']['cron']['weekday']

  backup_enabled app_backup_enabled
  backup_aws_access_key_id lazy { app_backup_enabled ? vlt.read("iam/#{node['volgactf']['qualifier']['backup']['aws']['credential']}", prefix: 'aws', key: 'access_key_id') : nil }
  backup_aws_secret_access_key lazy { app_backup_enabled ? vlt.read("iam/#{node['volgactf']['qualifier']['backup']['aws']['credential']}", prefix: 'aws', key: 'secret_access_key') : nil }
  backup_aws_default_region node['volgactf']['qualifier']['backup']['aws']['default_region']
  backup_aws_s3_bucket node['volgactf']['qualifier']['backup']['aws']['s3_bucket_name']
  backup_cron_mailto node['volgactf']['qualifier']['backup']['cron']['mailto']
  backup_cron_mailfrom node['volgactf']['qualifier']['backup']['cron']['mailfrom']
  backup_cron_minute node['volgactf']['qualifier']['backup']['cron']['minute']
  backup_cron_hour node['volgactf']['qualifier']['backup']['cron']['hour']
  backup_cron_day node['volgactf']['qualifier']['backup']['cron']['day']
  backup_cron_month node['volgactf']['qualifier']['backup']['cron']['month']
  backup_cron_weekday node['volgactf']['qualifier']['backup']['cron']['weekday']

  geoip2_city_database(lazy { ::ChefCookbook::GeoLite2.city_database(node, 'default') })
  geoip2_country_database(lazy { ::ChefCookbook::GeoLite2.country_database(node, 'default') })

  postgres_host '127.0.0.1'
  postgres_port node['postgres']['port']
  postgres_db node['volgactf']['qualifier']['database']['name']

  postgres_user lazy { vlt.read("#{node['name']}/#{node['volgactf']['qualifier']['database']['credential']}", prefix: 'postgres', key: 'user') }
  postgres_password lazy { vlt.read("#{node['name']}/#{node['volgactf']['qualifier']['database']['credential']}", prefix: 'postgres', key: 'password') }

  redis_host '127.0.0.1'
  redis_port 6379
  redis_db 1

  google_tag_id node['volgactf']['qualifier']['google']['tag_id']

  smtp_host node['volgactf']['qualifier']['smtp']['host']
  smtp_port node['volgactf']['qualifier']['smtp']['port']
  smtp_secure node['volgactf']['qualifier']['smtp']['secure']
  smtp_username lazy { smtp_credential ? vlt.read(node['volgactf']['qualifier']['smtp']['credential'], prefix: 'smtp', key: 'user') : nil }
  smtp_password lazy { smtp_credential ? vlt.read(node['volgactf']['qualifier']['smtp']['credential'], prefix: 'smtp', key: 'password') : nil }
  smtp_headers node['volgactf']['qualifier']['smtp']['headers']

  notification_post_twitter post_twitter
  twitter_api_consumer_key lazy { post_twitter ? vlt.read(node['volgactf']['qualifier']['notification']['twitter']['credential'], prefix: 'twitter', key: 'consumer_key') : nil }
  twitter_api_consumer_secret lazy { post_twitter ? vlt.read(node['volgactf']['qualifier']['notification']['twitter']['credential'], prefix: 'twitter', key: 'consumer_secret') : nil }
  twitter_api_access_token lazy { post_twitter ? vlt.read(node['volgactf']['qualifier']['notification']['twitter']['credential'], prefix: 'twitter', key: 'access_token') : nil }
  twitter_api_access_token_secret lazy { post_twitter ? vlt.read(node['volgactf']['qualifier']['notification']['twitter']['credential'], prefix: 'twitter', key: 'access_token_secret') : nil }

  notification_post_telegram post_telegram
  telegram_chat_id lazy { post_telegram ? vlt.read(node['volgactf']['qualifier']['notification']['telegram']['credential'], prefix: 'telegram', key: 'chat_id') : nil }
  telegram_bot_access_token lazy { post_telegram ? vlt.read(node['volgactf']['qualifier']['notification']['telegram']['credential'], prefix: 'telegram', key: 'bot_access_token') : nil }
  # telegram_socks5_host node['volgactf']['qualifier']['notification']['telegram']['socks5']['host']
  # telegram_socks5_port node['volgactf']['qualifier']['notification']['telegram']['socks5']['port']
  # telegram_socks5_username lazy { telegram_socks5_enabled ? vault.read('telegram/socks5', 'username') : nil }
  # telegram_socks5_password lazy { telegram_socks5_enabled ? vault.read('telegram/socks5', 'password') : nil }

  ctftime_oauth_client_id lazy { node['volgactf']['qualifier']['ctftime']['oauth']['enabled'] ? vlt.read("oauth/#{node['volgactf']['qualifier']['ctftime']['oauth']['client_credential']}", prefix: 'ctftime', key: 'client_id') : nil }
  ctftime_oauth_client_secret lazy { node['volgactf']['qualifier']['ctftime']['oauth']['enabled'] ? vlt.read("oauth/#{node['volgactf']['qualifier']['ctftime']['oauth']['client_credential']}", prefix: 'ctftime', key: 'client_secret') : nil }

  scoring_dynlog_min node['volgactf']['qualifier']['scoring']['dynlog']['min']
  scoring_dynlog_max node['volgactf']['qualifier']['scoring']['dynlog']['max']
  scoring_dynlog_k node['volgactf']['qualifier']['scoring']['dynlog']['k']
  scoring_dynlog_v node['volgactf']['qualifier']['scoring']['dynlog']['v']

  check_template_mtime node['volgactf']['qualifier']['check_template_mtime']

  post_max_task_file_size node['volgactf']['qualifier']['post_max_task_file_size']

  action :install
end

firewall_rule 'http' do
  stateful :new
  protocol :tcp
  port 80
  if node['volgactf']['qualifier']['proxied'] && !node['volgactf']['qualifier']['proxy_source'].nil?
    source "#{node['volgactf']['qualifier']['proxy_source']}/32"
  elsif !node['firewall']['ipv6_enabled']
    source '0.0.0.0/0'
  end
end

if node['volgactf']['qualifier']['secure'] && (!node['volgactf']['qualifier']['proxied'] || node['volgactf']['qualifier']['proxy_source'].nil?)
  firewall_rule 'https' do
    stateful :new
    protocol :tcp
    port 443
    unless node['firewall']['ipv6_enabled']
      source '0.0.0.0/0'
    end
  end
end

if node['netdata']['enabled']
  %w(autoconf autoconf-archive autogen automake cmake curl gcc git gzip libelf-dev libjson-c-dev libjudy-dev liblz4-dev libmnl-dev libssl-dev libtool libuv1-dev make netcat pkg-config python3 tar uuid-dev zlib1g-dev).each do |pkg_name|
    package pkg_name
  end

  netdata_install 'default' do
    install_method 'source'
    git_repository node['netdata']['git_repository']
    git_revision node['netdata']['git_revision']
    git_source_directory '/opt/netdata'
    autoupdate false
    update false
  end

  netdata_global_conf = {
    'memory mode' => 'dbengine',
    'page cache size' => node['netdata']['page cache size'],
    'dbengine multihost disk space' => node['netdata']['dbengine multihost disk space']
  }

  unless node['netdata']['bind to'].nil?
    netdata_global_conf['bind to'] = node['netdata']['bind to']
  end

  netdata_config 'global' do
    owner 'netdata'
    group 'netdata'
    configurations netdata_global_conf
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

  netdata_python_plugin 'nginx' do
    owner 'netdata'
    group 'netdata'
    global_configuration(
      'retries' => 5,
      'update_every' => 1
    )
    jobs(
      'local' => {
        'url' => "http://#{stub_status_host}:#{stub_status_port}/stub_status"
      }
    )
    notifies :restart, 'service[netdata]', :delayed
  end

  package 'python-is-python3'
  package 'python3-psycopg2'

  netdata_python_plugin 'postgres' do
    owner 'netdata'
    group 'netdata'
    global_configuration(
      'retries' => 5,
      'update_every' => 1
    )
    jobs(lazy {
      {
        'local' => {
          'host' => '127.0.0.1',
          'port' => node['postgres']['port'],
          'database' => node['volgactf']['qualifier']['database']['name'],
          'user' => vlt.read("#{node['name']}/#{node['postgres']['root_credential']}", prefix: 'postgres', key: 'user'),
          'password' => vlt.read("#{node['name']}/#{node['postgres']['root_credential']}", prefix: 'postgres', key: 'password')
        }
      }
    })
    sensitive true
  end

  firewall_rule 'netdata' do
    stateful :new
    protocol :tcp
    port 19999
    if node['netdata']['allow_from'].nil?
      source '0.0.0.0/0'
    else
      source node['netdata']['allow_from']
    end
  end
end
