# frozen_string_literal: true

default['ngx']['version'] = '1.21.1'
default['ngx']['checksum'] = '68ba0311342115163a0354cad34f90c05a7e8bf689dc498abf07899eda155560'

default['ngx']['logrotate']['rotate'] = 168

default['ngx']['gzip']['enabled'] = true
default['ngx']['gzip']['comp_level'] = 4
default['ngx']['gzip']['min_length'] = 1024

default['ngx']['brotli']['enabled'] = true
default['ngx']['brotli']['comp_level'] = 5
default['ngx']['brotli']['min_length'] = 1024

default['ngx']['realip']['header'] = 'X-Forwarded-For'
default['ngx']['realip']['from'] = ['127.0.0.1']
