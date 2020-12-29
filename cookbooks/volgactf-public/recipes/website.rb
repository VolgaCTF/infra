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

firewall_rule 'icmpv6' do
  protocol :'ipv6-icmp'
  command :allow
end

firewall_rule 'ssh' do
  stateful :new
  protocol :tcp
  port node['volgactf-public']['ssh_port']
end

firewall_rule 'wireguard' do
  stateful :new
  protocol :udp
  source '0.0.0.0/0'
  port node['volgactf-public']['wireguard_port']
  command :allow
end

include_recipe 'nodejs::default'

ngx_http_ssl_module 'default' do
  openssl_version node['openssl']['version']
  openssl_checksum node['openssl']['checksum']
  action :add
end

ngx_http_v2_module 'default'
ngx_http_stub_status_module 'default'
ngx_http_dav_module 'default'
ngx_http_dav_ext_module 'default'

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
      worker_processes: 'auto'
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
      keepalive_requests: 250,
      keepalive_timeout: 100
    }
  )
  action :run
end

nginx_conf 'gzip' do
  cookbook 'volgactf-public'
  template 'nginx/gzip.conf.erb'
  action :create
end

nginx_conf 'resolver' do
  cookbook 'volgactf-public'
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
      ssl_configuration: 'modern'
    }
  })
  action :create
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

vlt = ::Vlt::Client.new(::Vlt.file_auth_provider)
tls_vlt = ::Vlt::Client.new(::Vlt.file_auth_provider, 'tls')
tls_vlt_provider = lambda { tls_vlt }

volgactf_public_website node['volgactf-public']['website']['fqdn'] do
  user node['volgactf-public']['user']
  group node['volgactf-public']['group']
  listen_ipv6 true
  access_log_options 'combined'
  error_log_options 'warn'
  vlt_provider tls_vlt_provider
  vlt_format 2
  action :install
end

node['volgactf-public']['website']['redirects'].each do |item|
  redirect_host item['fqdn'] do
    target item['target']
    path item.fetch('path', '')
    listen_ipv6 true
    default_server false
    secure true
    permanent item.fetch('permanent', false)
    pass_request_uri true
    access_log_options 'combined'
    error_log_options 'warn'
    vlt_provider tls_vlt_provider
    vlt_format 2
    action :create
  end
end

firewall_rule 'http' do
  stateful :new
  protocol :tcp
  port 80
end

firewall_rule 'https' do
  stateful :new
  protocol :tcp
  port 443
end
