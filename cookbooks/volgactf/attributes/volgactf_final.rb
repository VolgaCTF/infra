# frozen_string_literal: true

default['volgactf']['final']['database']['credential'] = 'volgactf_final'
default['volgactf']['final']['database']['name'] = 'volgactf_final'

default['volgactf']['final']['master']['repo_mode'] = 'https'
default['volgactf']['final']['master']['run_mode'] = 'production'
default['volgactf']['final']['master']['log_level'] = 'INFO'

default['volgactf']['final']['master']['web_processes'] = 2
default['volgactf']['final']['master']['queue_processes'] = 2
default['volgactf']['final']['master']['stream_processes'] = 2

default['volgactf']['final']['master']['public']['fqdn'] = nil
default['volgactf']['final']['master']['public']['listen'] = nil
default['volgactf']['final']['master']['public']['default_server'] = true
default['volgactf']['final']['master']['public']['secure'] = true
default['volgactf']['final']['master']['public']['oscp_stapling'] = true

default['volgactf']['final']['master']['internal']['host'] = nil
default['volgactf']['final']['master']['internal']['port'] = 8000
default['volgactf']['final']['master']['internal']['default_server'] = true

default['volgactf']['final']['master']['proxied']['fqdn'] = nil
default['volgactf']['final']['master']['proxied']['listen'] = nil
default['volgactf']['final']['master']['proxied']['port'] = 9000
default['volgactf']['final']['master']['proxied']['default_server'] = true

default['volgactf']['final']['master']['branding']['root'] = 'branding-sample'
default['volgactf']['final']['master']['branding']['folders'] = %w[
  images
  js
]
default['volgactf']['final']['master']['branding']['files'] = %w[
  images/volgactf-logo.svg
  js/content.js
  js/logo.js
  js/theme.js
]

default['volgactf']['final']['vault']['credential'] = nil

default['volgactf']['final']['checker']['network']['name'] = 'checker'
default['volgactf']['final']['checker']['network']['subnet'] = '192.168.251.0/24'
default['volgactf']['final']['checker']['network']['gateway'] = '192.168.251.1'

default['volgactf']['final']['checker']['image']['name'] = nil
default['volgactf']['final']['checker']['image']['registry'] = nil
default['volgactf']['final']['checker']['image']['repo'] = nil
default['volgactf']['final']['checker']['image']['tag'] = 'latest'

default['volgactf']['final']['checker']['listen'] = nil
default['volgactf']['final']['checker']['default_server'] = true
default['volgactf']['final']['checker']['processes'] = 2
default['volgactf']['final']['checker']['environment'] = {}
