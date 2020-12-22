name 'website'

default_source :supermarket

require './lib/helpers'

local_cookbook 'volgactf-public', '../cookbooks/volgactf-public'

run_list 'recipe[volgactf-public::website]'