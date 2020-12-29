name 'website'

default_source :supermarket

require './lib/helpers'

local_cookbook 'volgactf-public', '../cookbooks/volgactf-public'

run_list 'recipe[volgactf-public::vault_renew_lease]',
  'recipe[volgactf-public::chef_client_run]',
  'recipe[volgactf-public::packages]',
  'recipe[volgactf-public::locale]',
  'recipe[volgactf-public::time]',
  'recipe[volgactf-public::website]'
