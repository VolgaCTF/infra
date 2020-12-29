require 'vault'
require 'json'

def get_instance_policy_name(prefix, instance)
  "#{prefix}__#{instance}"
end

def get_instance_role_name(prefix, instance)
  "#{prefix}__#{instance}"
end

def get_token_policy_name(prefix, instance)
  "#{prefix}__#{instance}__token"
end

def get_instance_policy(prefix, instance)
  case instance
  when 'jupiter'
    policy = <<~EOL
      path "tls/data/certificate/index" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_ecc" {
        capabilities = ["read"]
      }

      path "telegram/data/#{instance}" {
        capabilities = ["read"]
      }
    EOL
  else
    policy = ''
  end
  policy
end

def get_token_policy(instance_role_name)
  policy = <<~EOL
    path "auth/approle/role/#{instance_role_name}/secret-id" {
      capabilities = ["update"]
    }

    path "auth/approle/role/#{instance_role_name}/role-id" {
      capabilities = ["read"]
    }
  EOL
end

client = ::Vault::Client.new(address: ENV['VAULT_ADDR'], token: ENV['VAULT_TOKEN'])
prefix = 'private'

instances = [
  'jupiter'
]

repo_policies = {}
role_policy_bindings = {}
token_info = {}

puts "Ask whether to create tokens? (yes/no, default: no)"
ask_create_tokens = gets.chomp == 'yes'

instances.each do |instance|
  instance_role_name = get_instance_role_name(prefix, instance)
  instance_policy_name = get_instance_policy_name(prefix, instance)
  token_policy_name = get_token_policy_name(prefix, instance)
  repo_policies[instance_policy_name] = get_instance_policy(prefix, instance)
  repo_policies[token_policy_name] = get_token_policy(instance_role_name)
  role_policy_bindings[instance_role_name] = instance_policy_name
  if ask_create_tokens
    puts "Create token for #{instance}? (yes/no, default: no)"
    if gets.chomp == 'yes'
      token_info[instance] = {
        'approle' => instance_role_name,
        'policy' => token_policy_name
      }
    end
  end
end

server_policies = client.sys.policies
create_policy_names = repo_policies.keys - server_policies
existing_policy_names = repo_policies.keys & server_policies

create_policy_names.each do |policy_name|
  client.sys.put_policy(policy_name, repo_policies[policy_name])
  puts "Created policy #{policy_name}"
end

existing_policy_names.each do |policy_name|
  policy = client.sys.policy(policy_name)
  if policy.rules != repo_policies[policy_name]
    client.sys.put_policy(policy_name, repo_policies[policy_name])
    puts "Updated policy #{policy_name}"
  end
end

role_policy_bindings.each do |key, val|
  path = "auth/approle/role/#{key}"
  r = client.logical.read(path)
  if r.nil? || r.data[:policies] != [val]
    client.logical.write(path, policies: [val])
    puts "Wrote data to #{path}"
  end
end

token_info.each do |key, val|
  r = client.auth_token.create(
    policies: [val['policy']],
    display_name: key,
    renewable: true,
    ttl: '720h',
    duration: '720h',
    explicit_max_ttl: '8760h'
  )
  auth_data = {
    'address' => ENV['VAULT_ADDR'],
    'token' => r.auth.client_token,
    'approle' => val['approle'],
  }
  puts "Auth for #{key}\n==========\n#{JSON.pretty_generate(auth_data)}\n==========\n"
end
