# frozen_string_literal: true

sysctl 'net.ipv4.ip_nonlocal_bind' do
  value 1
  action :apply
end

ngx_http_stub_status_module 'default'

nginx_install 'default' do
  version node['ngx']['version']
  checksum node['ngx']['checksum']
  with_threads false
  with_debug false
  directives(
    main: {
      worker_processes: 'auto',
      worker_rlimit_nofile: 1024
    },
    events: {
      worker_connections: 1024,
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

docker_service 'default' do
  action [:create, :start]
end

docker_network node['volgactf']['final']['checker']['network']['name'] do
  subnet node['volgactf']['final']['checker']['network']['subnet']
  gateway node['volgactf']['final']['checker']['network']['gateway']
end

vlt = ::Vlt::Client.new(::Vlt.file_auth_provider)

unless node['volgactf']['final']['checker']['image']['registry'].nil?
  docker_registry node['volgactf']['final']['checker']['image']['registry'] do
    serveraddress(lazy do
      host = vlt.read(node['volgactf']['final']['checker']['image']['registry'], prefix: 'docker', key: 'host')
      port = vlt.read(node['volgactf']['final']['checker']['image']['registry'], prefix: 'docker', key: 'port')
      %(https://#{host}#{port == 443 ? '' : ":#{port}"}/)
    end)
    username(lazy { vlt.read(node['volgactf']['final']['checker']['image']['registry'], prefix: 'docker', key: 'username') })
    password(lazy { vlt.read(node['volgactf']['final']['checker']['image']['registry'], prefix: 'docker', key: 'password') })
    action :login
  end
end

volgactf_final_checker node['volgactf']['final']['checker']['image']['name'] do
  listen node['volgactf']['final']['checker']['listen']
  default_server node['volgactf']['final']['checker']['default_server']
  docker_image_repo(lazy do
    if node['volgactf']['final']['checker']['image']['registry'].nil?
      node['volgactf']['final']['checker']['image']['repo']
    else
      host = vlt.read(node['volgactf']['final']['checker']['image']['registry'], prefix: 'docker', key: 'host')
      port = vlt.read(node['volgactf']['final']['checker']['image']['registry'], prefix: 'docker', key: 'port')
      %(#{host}#{port == 443 ? '' : ":#{port}"}/#{node['volgactf']['final']['checker']['image']['repo']})
    end
  end)
  docker_image_tag node['volgactf']['final']['checker']['image']['tag']
  docker_network_name node['volgactf']['final']['checker']['network']['name']
  docker_network_gateway node['volgactf']['final']['checker']['network']['gateway']
  auth_checker_username(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/auth/checker", prefix: 'volgactf', key: 'username') })
  auth_checker_password(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/auth/checker", prefix: 'volgactf', key: 'password') })
  auth_master_username(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/auth/master", prefix: 'volgactf', key: 'username') })
  auth_master_password(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/auth/master", prefix: 'volgactf', key: 'password') })
  flag_sign_key_public(lazy { vlt.read("final/#{node['volgactf']['final']['vault']['credential']}/flag/sign_key/public", prefix: 'volgactf', key: 'key') })
  processes node['volgactf']['final']['checker']['processes']
  environment node['volgactf']['final']['checker']['environment']
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
end
