# frozen_string_literal: true

node.default['firewall']['iptables']['defaults'][:ruleset] = {
  '*filter' => 1,
  ':INPUT DROP' => 2,
  ':FORWARD DROP' => 3,
  ':OUTPUT ACCEPT' => 4,
  'COMMIT_FILTER' => 100
}

firewall 'default' do
  ipv6_enabled node['firewall']['ipv6_enabled']
  action :install
end

firewall_rule 'related,established' do
  stateful %i[related established]
  protocol :none
  command :allow
end

firewall_rule 'loopback' do
  interface 'lo'
  protocol :none
  command :allow
end

firewall_rule 'icmp' do
  protocol :icmp
  source '0.0.0.0/0'
  command :allow
end

if node['firewall']['ipv6_enabled']
  firewall_rule 'icmpv6' do
    protocol :'ipv6-icmp'
    command :allow
  end
end

firewall_rule 'ssh' do
  stateful :new
  protocol :tcp
  port node['volgactf']['firewall']['ssh_port']
end

node['volgactf']['firewall']['rules'].each do |name_, params|
  firewall_rule name_ do
    stateful params['stateful'].to_sym unless params.fetch('stateful', nil).nil?
    port params['port'] unless params.fetch('port', nil).nil?
    source params['source'] unless params.fetch('source', nil).nil?
    interface params['interface'] unless params.fetch('interface', nil).nil?
    protocol params.fetch('protocol', 'tcp').to_sym
    command params.fetch('command', 'allow').to_sym
    action :create
  end
end
