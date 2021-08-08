# frozen_string_literal: true

default['netdata']['enabled'] = false
default['netdata']['update'] = false

default['netdata']['git_repository'] = 'https://github.com/netdata/netdata.git'
default['netdata']['git_revision'] = 'v1.31.0'

default['netdata']['global']['hostname'] = nil
default['netdata']['global']['bind_to'] = nil
default['netdata']['global']['page cache size'] = 32
default['netdata']['global']['dbengine multihost disk space'] = 1024

default['netdata']['registry']['enabled'] = false
default['netdata']['registry']['registry hostname'] = nil
default['netdata']['registry']['registry to announce'] = 'https://jupiter.wan.volgactf.org:19999'

default['netdata']['health_alarm_notify']['telegram']['enabled'] = true
default['netdata']['health_alarm_notify']['telegram']['credential'] = 'monitoring'
