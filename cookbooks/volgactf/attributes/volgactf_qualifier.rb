default['volgactf']['qualifier']['fqdn'] = nil
default['volgactf']['qualifier']['secure'] = true
default['volgactf']['qualifier']['ocsp_stapling'] = true
default['volgactf']['qualifier']['optimize_delivery'] = true

default['volgactf']['qualifier']['proxied'] = false

default['volgactf']['qualifier']['email']['transport'] = 'smtp'
default['volgactf']['qualifier']['email']['webhook'] = nil
default['volgactf']['qualifier']['email']['sender_name'] = 'VolgaCTF Qualifier'
default['volgactf']['qualifier']['email']['sender_address'] = nil

default['volgactf']['qualifier']['email']['address_validator'] = 'default'
default['volgactf']['qualifier']['email']['address_validator_ignore_list'] = []

default['volgactf']['qualifier']['smtp']['host'] = nil
default['volgactf']['qualifier']['smtp']['port'] = nil
default['volgactf']['qualifier']['smtp']['secure'] = true
default['volgactf']['qualifier']['smtp']['credential'] = nil
default['volgactf']['qualifier']['smtp']['headers'] = {}

default['volgactf']['qualifier']['google']['tag_id'] = nil

default['volgactf']['qualifier']['num_processes_server'] = 2
default['volgactf']['qualifier']['num_processes_queue'] = 2

default['volgactf']['qualifier']['database']['credential'] = 'volgactf_qualifier'
default['volgactf']['qualifier']['database']['name'] = 'volgactf_qualifier'

default['volgactf']['qualifier']['customizer_name'] = 'default'
default['volgactf']['qualifier']['customizers'] = {}

default['volgactf']['qualifier']['cleanup_upload_dir']['enabled'] = false
default['volgactf']['qualifier']['cleanup_upload_dir']['cron']['mailto'] = nil
default['volgactf']['qualifier']['cleanup_upload_dir']['cron']['mailfrom'] = nil
default['volgactf']['qualifier']['cleanup_upload_dir']['cron']['minute'] = '*/10'
default['volgactf']['qualifier']['cleanup_upload_dir']['cron']['hour'] = '*'
default['volgactf']['qualifier']['cleanup_upload_dir']['cron']['day'] = '*'
default['volgactf']['qualifier']['cleanup_upload_dir']['cron']['month'] = '*'
default['volgactf']['qualifier']['cleanup_upload_dir']['cron']['weekday'] = '*'

default['volgactf']['qualifier']['backup']['enabled'] = false
default['volgactf']['qualifier']['backup']['aws']['default_region'] = nil
default['volgactf']['qualifier']['backup']['aws']['credential'] = nil
default['volgactf']['qualifier']['backup']['aws']['s3_bucket_name'] = nil
default['volgactf']['qualifier']['backup']['cron']['mailto'] = nil
default['volgactf']['qualifier']['backup']['cron']['mailfrom'] = nil
default['volgactf']['qualifier']['backup']['cron']['minute'] = '*'
default['volgactf']['qualifier']['backup']['cron']['hour'] = '*'
default['volgactf']['qualifier']['backup']['cron']['day'] = '*'
default['volgactf']['qualifier']['backup']['cron']['month'] = '*'
default['volgactf']['qualifier']['backup']['cron']['weekday'] = '*'

default['volgactf']['qualifier']['notification']['twitter']['enabled'] = false
default['volgactf']['qualifier']['notification']['twitter']['credential'] = nil

default['volgactf']['qualifier']['notification']['telegram']['enabled'] = false
default['volgactf']['qualifier']['notification']['telegram']['credential'] = nil
# default['volgactf']['qualifier']['notification']['telegram']['socks5']['enabled'] = false
# default['volgactf']['qualifier']['notification']['telegram']['socks5']['host'] = nil
# default['volgactf']['qualifier']['notification']['telegram']['socks5']['port'] = ni

default['volgactf']['qualifier']['ctftime']['oauth']['enabled'] = false
default['volgactf']['qualifier']['ctftime']['oauth']['client_credential'] = nil

default['volgactf']['qualifier']['scoring']['dynlog']['min'] = 50
default['volgactf']['qualifier']['scoring']['dynlog']['max'] = 500
default['volgactf']['qualifier']['scoring']['dynlog']['k'] = 81.1
default['volgactf']['qualifier']['scoring']['dynlog']['v'] = 3.2

default['volgactf']['qualifier']['check_template_mtime'] = false

default['volgactf']['qualifier']['post_max_task_file_size'] = 100
