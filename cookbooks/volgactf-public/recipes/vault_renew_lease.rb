vlt = ::Vlt::Client.new(::Vlt.file_auth_provider)

ruby_block 'renew Vault token lease' do
  block do
    vlt.renew_lease
  end
  action :run
end
