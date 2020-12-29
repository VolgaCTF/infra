apt_update 'default' do
  frequency 86_400
  action :periodic
end

build_essential 'default' do
  action :install
end
