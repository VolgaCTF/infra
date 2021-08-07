# frozen_string_literal: true

ngx_http_ssl_module 'default' do
  openssl_version node['openssl']['version']
  openssl_checksum node['openssl']['checksum']
  action :add
end

ngx_http_v2_module 'default'
ngx_http_gzip_static_module 'default'
ngx_brotli_module 'default'
ngx_http_stub_status_module 'default'

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
      ssl_configuration: 'modern'
    }
  end)
  action :create
end

logrotate_app 'nginx' do
  path(lazy { ::File.join(node.run_state['nginx']['log_dir'], '*.log') })
  frequency 'daily'
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

tls_vlt = ::Vlt::Client.new(::Vlt.file_auth_provider, 'tls')
tls_vlt_provider = -> { tls_vlt }

volgactf_website node['volgactf']['website']['fqdn'] do
  user node['volgactf']['user']
  group node['volgactf']['group']
  listen_ipv6 node['firewall']['ipv6_enabled']
  access_log_options 'combined'
  error_log_options 'warn'
  vlt_provider tls_vlt_provider
  vlt_format 2
  action :install
end

node['volgactf']['website']['redirects'].each do |item|
  redirect_host item['fqdn'] do
    target item['target']
    path item.fetch('path', '')
    listen_ipv6 node['firewall']['ipv6_enabled']
    default_server false
    secure true
    permanent item.fetch('permanent', false)
    pass_request_uri false
    access_log_options 'combined'
    error_log_options 'warn'
    vlt_provider tls_vlt_provider
    vlt_format 2
    action :create
  end
end

unless node['volgactf']['qualifier_proxy']['fqdn'].nil? || node['volgactf']['qualifier_proxy']['ipv4_address'].nil?
  volgactf_qualifier_proxy node['volgactf']['qualifier_proxy']['fqdn'] do
    ipv4_address node['volgactf']['qualifier_proxy']['ipv4_address']
    vlt_provider tls_vlt_provider
  end
end
