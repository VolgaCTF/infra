# frozen_string_literal: true

sysctl 'net.ipv4.ip_nonlocal_bind' do
  value 1
  action :apply
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
ngx_http_js_module 'default'

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

nginx_conf 'gzip' do
  cookbook 'volgactf'
  template 'nginx/gzip.conf.erb'
  variables(
    enabled: node['ngx']['gzip']['enabled'],
    comp_level: node['ngx']['gzip']['comp_level'],
    min_length: node['ngx']['gzip']['min_length']
  )
  action :create
end

nginx_conf 'brotli' do
  cookbook 'volgactf'
  template 'nginx/brotli.conf.erb'
  variables(
    enabled: node['ngx']['brotli']['enabled'],
    comp_level: node['ngx']['brotli']['comp_level'],
    min_length: node['ngx']['brotli']['min_length']
  )
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
  variables(lazy do
    {
      ssl_dhparam: ::ChefCookbook::DHParam.file(node, 'default'),
      ssl_configuration: 'intermediate'
    }
  end)
  action :create
end

nginx_conf 'realip' do
  cookbook 'volgactf'
  template 'nginx/realip.conf.erb'
  variables(
    header: node['ngx']['realip']['header'],
    from: node['ngx']['realip']['from']
  )
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

package 'cron'

service 'cron' do
  action :nothing
end

execute 'run logrotate hourly' do
  command 'mv /etc/cron.daily/logrotate /etc/cron.hourly/logrotate'
  user 'root'
  group node['root_group']
  notifies :restart, 'service[cron]', :delayed
  action :run
  not_if { ::File.exist?('/etc/cron.hourly/logrotate') }
end

logrotate_app 'nginx' do
  path(lazy { ::File.join(node.run_state['nginx']['log_dir'], '*.log') })
  frequency 'hourly'
  rotate node['ngx']['logrotate']['rotate']
  options %w[
    missingok
    compress
    delaycompress
    notifempty
  ]
  postrotate(lazy { "[ ! -f #{node.run_state['nginx']['pid']} ] || kill -USR1 `cat #{node.run_state['nginx']['pid']}`" })
  action :enable
end

sysctl 'vm.overcommit_memory' do
  value 1
  action :apply
end

vlt = ::Vlt::Client.new(::Vlt.file_auth_provider)

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

postgresql_user 'volgactf final user' do
  create_user lazy { vlt.read("#{node['name']}/#{node['volgactf']['final']['database']['credential']}", prefix: 'postgres', key: 'user') }
  password lazy { vlt.read("#{node['name']}/#{node['volgactf']['final']['database']['credential']}", prefix: 'postgres', key: 'password') }
  action :create
end

postgresql_database node['volgactf']['final']['database']['name'] do
  locale node['postgres']['locale']
  owner lazy { vlt.read("#{node['name']}/#{node['volgactf']['final']['database']['credential']}", prefix: 'postgres', key: 'user') }
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

volgactf_ruby node['ruby']['version'] do
  user node['volgactf']['user']
  group node['volgactf']['group']
  user_home ::File.join('/home', node['volgactf']['user'])
  bundler_version node['ruby']['bundler_version']
  action :install
end

ssh_known_hosts_entry 'github.com' if node['volgactf']['final']['master']['repo_mode'] == 'ssh'

tls_vlt = ::Vlt::Client.new(::Vlt.file_auth_provider, 'tls')
tls_vlt_provider = -> { tls_vlt }

volgactf_final_master 'default' do
  user node['volgactf']['user']
  user_home ::File.join('/home', node['volgactf']['user'])
  group node['volgactf']['group']

  repo_mode node['volgactf']['final']['master']['repo_mode']
  run_mode node['volgactf']['final']['master']['run_mode']

  ruby_version node['ruby']['version']

  redis_host node['redisio']['servers'][0]['address']
  redis_port node['redisio']['servers'][0]['port']

  postgres_host '127.0.0.1'
  postgres_port node['postgres']['port']
  postgres_db node['volgactf']['final']['database']['name']

  postgres_user(lazy { vlt.read("#{node['name']}/#{node['volgactf']['final']['database']['credential']}", prefix: 'postgres', key: 'user') })
  postgres_password(lazy { vlt.read("#{node['name']}/#{node['volgactf']['final']['database']['credential']}", prefix: 'postgres', key: 'password') })

  internal_host node['volgactf']['final']['master']['internal']['host']
  internal_port node['volgactf']['final']['master']['internal']['port']
  internal_default_server node['volgactf']['final']['master']['internal']['default_server']

  public_fqdn node['volgactf']['final']['master']['public']['fqdn']
  public_listen node['volgactf']['final']['master']['public']['listen']
  public_default_server node['volgactf']['final']['master']['public']['default_server']
  public_secure node['volgactf']['final']['master']['public']['secure']
  public_oscp_stapling node['volgactf']['final']['master']['public']['oscp_stapling']

  proxied_fqdn node['volgactf']['final']['master']['proxied']['fqdn']
  proxied_listen node['volgactf']['final']['master']['proxied']['listen']
  proxied_port node['volgactf']['final']['master']['proxied']['port']
  proxied_default_server node['volgactf']['final']['master']['proxied']['default_server']

  auth_checker_username(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/auth/checker", prefix: 'volgactf', key: 'username') })
  auth_checker_password(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/auth/checker", prefix: 'volgactf', key: 'password') })

  auth_master_username(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/auth/master", prefix: 'volgactf', key: 'username') })
  auth_master_password(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/auth/master", prefix: 'volgactf', key: 'password') })

  flag_generator_secret(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/flag/generator", prefix: 'volgactf', key: 'secret') })
  flag_sign_key_private(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/flag/sign_key/private", prefix: 'volgactf', key: 'key') })
  flag_sign_key_public(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/flag/sign_key/public", prefix: 'volgactf', key: 'key') })

  web_processes node['volgactf']['final']['master']['web_processes']
  queue_processes node['volgactf']['final']['master']['queue_processes']
  stream_processes node['volgactf']['final']['master']['stream_processes']

  log_level node['volgactf']['final']['master']['log_level']

  config node['volgactf']['final']['config']

  branding_cookbook 'volgactf'
  branding_root node['volgactf']['final']['master']['branding']['root']
  branding_folders node['volgactf']['final']['master']['branding']['folders']
  branding_files node['volgactf']['final']['master']['branding']['files']

  vlt_provider tls_vlt_provider

  action :install
end

if node['netdata']['enabled']
  service 'netdata' do
    action :nothing
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
        'url' => "http://#{stub_status_host}:#{stub_status_port}#{stub_status_path}"
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
    jobs(lazy do
      {
        'local' => {
          'host' => '127.0.0.1',
          'port' => node['postgres']['port'],
          'database' => node['volgactf']['final']['database']['name'],
          'user' => vlt.read("#{node['name']}/#{node['postgres']['root_credential']}", prefix: 'postgres', key: 'user'),
          'password' => vlt.read("#{node['name']}/#{node['postgres']['root_credential']}", prefix: 'postgres', key: 'password')
        }
      }
    end)
    sensitive true
  end
end
