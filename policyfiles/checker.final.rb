# frozen_string_literal: true

name 'checker.final'

default_source :supermarket

require './lib/helpers'

github_cookbook 'ssmtp-lwrp', 'aspyatkin/ssmtp-lwrp-cookbook', tag: 'v0.2.0'
github_cookbook 'cronic', 'aspyatkin/cronic-cookbook', tag: 'v2.0.1'
github_cookbook 'volgactf-qualifier', 'VolgaCTF/volgactf-qualifier-cookbook', tag: 'v2.2.0'
github_cookbook 'volgactf-final', 'VolgaCTF/volgactf-final-cookbook', tag: 'v1.5.0'
github_cookbook 'netdata', 'jmadureira/netdata-cookbook', branch: '336d91d15098d6240d2861fb992be5f52a318005'

local_cookbook 'volgactf', '../cookbooks/volgactf'

run_list 'recipe[volgactf::vault_renew_lease]',
         'recipe[volgactf::chef_client_run]',
         'recipe[volgactf::packages]',
         'recipe[volgactf::locale]',
         'recipe[volgactf::time]',
         'recipe[volgactf::firewall]',
         'recipe[volgactf::netdata]',
         'recipe[volgactf::checker_final]'
