# frozen_string_literal: true

default['redisio']['version'] = '6.2.5'
default['redisio']['servers'] = [
  {
    'name' => nil,
    'address' => '127.0.0.1',
    'port' => 6_379
  }
]
