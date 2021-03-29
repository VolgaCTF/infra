if node['chef_client_run']['enabled']
  vlt = ::Vlt::Client.new(::Vlt::file_auth_provider)

  unit_status_telegram_service 'default' do
    telegram_bot_token lazy { vlt.read(node['chef_client_run']['telegram_credential'], prefix: 'telegram', key: 'bot_token') }
    telegram_chat_id lazy { vlt.read(node['chef_client_run']['telegram_credential'], prefix: 'telegram', key: 'chat_id') }
    action :setup
  end

  chef_client_run 'default' do
    on_calendar node['chef_client_run']['on_calendar']
    randomized_delay_sec node['chef_client_run']['randomized_delay_sec']
    action :setup
  end
else
  chef_client_run 'default' do
    action :uninstall
  end

  unit_status_telegram_service 'default' do
    action :uninstall
  end
end
