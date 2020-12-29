package 'locales'

locale 'system' do
  lang node['locale']['lang']
  lc_env node['locale']['lc_env']
  action :update
end
