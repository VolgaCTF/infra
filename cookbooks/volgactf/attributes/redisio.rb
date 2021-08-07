# frozen_string_literal: true

default['redisio']['version'] = '6.0.10'
default['redisio']['servers'] = [
  {
    'name' => nil,
    'address' => '127.0.0.1',
    'port' => 6_379
  }
]
