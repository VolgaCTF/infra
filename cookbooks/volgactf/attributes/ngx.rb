# frozen_string_literal: true

default['ngx']['version'] = '1.21.6'
default['ngx']['checksum'] = '66dc7081488811e9f925719e34d1b4504c2801c81dee2920e5452a86b11405ae'

default['ngx']['logrotate']['rotate'] = 168

default['ngx']['gzip']['enabled'] = true
default['ngx']['gzip']['comp_level'] = 4
default['ngx']['gzip']['min_length'] = 1024

default['ngx']['brotli']['enabled'] = true
default['ngx']['brotli']['comp_level'] = 5
default['ngx']['brotli']['min_length'] = 1024

default['ngx']['realip']['header'] = 'X-Forwarded-For'
default['ngx']['realip']['from'] = ['127.0.0.1']
