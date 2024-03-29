# frozen_string_literal: true

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

def get_instance_policy(_, instance)
  case instance
  when 'master.q.dev'
    <<~POLICY
      path "tls/data/certificate/index" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_dev_qualifier" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_dev_qualifier_ecc" {
        capabilities = ["read"]
      }

      path "telegram/data/monitoring" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_dev_qualifier_wan_ecc" {
        capabilities = ["read"]
      }

      path "maxmind/data/volgactf_dev_qualifier" {
        capabilities = ["read"]
      }

      path "postgres/data/#{instance}/*" {
        capabilities = ["read"]
      }

      path "aws/data/iam/volgactf_dev_qualifier_s3" {
        capabilities = ["read"]
      }

      path "smtp/data/volgactf_dev_qualifier_ses" {
        capabilities = ["read"]
      }

      path "telegram/data/volgactf_dev_qualifier" {
        capabilities = ["read"]
      }

      path "twitter/data/volgactf_dev_qualifier" {
        capabilities = ["read"]
      }

      path "ctftime/data/oauth/volgactf_dev_qualifier" {
        capabilities = ["read"]
      }
    POLICY
  when 'master.q.staging'
    <<~POLICY
      path "tls/data/certificate/index" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_staging_qualifier" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_staging_qualifier_ecc" {
        capabilities = ["read"]
      }

      path "telegram/data/monitoring" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_staging_qualifier_wan_ecc" {
        capabilities = ["read"]
      }

      path "maxmind/data/volgactf_staging_qualifier" {
        capabilities = ["read"]
      }

      path "postgres/data/#{instance}/*" {
        capabilities = ["read"]
      }

      path "aws/data/iam/volgactf_staging_qualifier_s3" {
        capabilities = ["read"]
      }

      path "smtp/data/volgactf_staging_qualifier_ses" {
        capabilities = ["read"]
      }

      path "telegram/data/volgactf_staging_qualifier" {
        capabilities = ["read"]
      }

      path "twitter/data/volgactf_staging_qualifier" {
        capabilities = ["read"]
      }

      path "ctftime/data/oauth/volgactf_staging_qualifier" {
        capabilities = ["read"]
      }
    POLICY
  when 'master.q.2022'
    <<~POLICY
      path "tls/data/certificate/index" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_2022_qualifier" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_2022_qualifier_ecc" {
        capabilities = ["read"]
      }

      path "telegram/data/monitoring" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_2022_qualifier_wan_ecc" {
        capabilities = ["read"]
      }

      path "maxmind/data/volgactf_2022_qualifier" {
        capabilities = ["read"]
      }

      path "postgres/data/#{instance}/*" {
        capabilities = ["read"]
      }

      path "aws/data/iam/volgactf_2022_qualifier_s3" {
        capabilities = ["read"]
      }

      path "smtp/data/volgactf_2022_qualifier_ses" {
        capabilities = ["read"]
      }

      path "telegram/data/volgactf_2022_qualifier" {
        capabilities = ["read"]
      }

      path "twitter/data/volgactf_2022_qualifier" {
        capabilities = ["read"]
      }

      path "ctftime/data/oauth/volgactf_2022_qualifier" {
        capabilities = ["read"]
      }
    POLICY
  when 'master.final.dev'
    <<~POLICY
      path "telegram/data/monitoring" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/index" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_dev_final_wan_ecc" {
        capabilities = ["read"]
      }

      path "postgres/data/#{instance}/*" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/development/auth/*" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/development/flag/generator" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/development/flag/sign_key/*" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_dev_final" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_dev_final_ecc" {
        capabilities = ["read"]
      }
    POLICY
  when 'checker1.final.dev', 'checker2.final.dev'
    <<~POLICY
      path "telegram/data/monitoring" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/index" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_dev_final_wan_ecc" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/development/auth/*" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/development/flag/sign_key/public" {
        capabilities = ["read"]
      }
    POLICY
  when 'master.final.2021'
    <<~POLICY
      path "telegram/data/monitoring" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/index" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_final_2021_wan_ecc" {
        capabilities = ["read"]
      }

      path "postgres/data/#{instance}/*" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/2021/auth/*" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/2021/flag/generator" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/2021/flag/sign_key/*" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_final" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_final_ecc" {
        capabilities = ["read"]
      }
    POLICY
  when 'checker1.final.2021', 'checker2.final.2021', 'checker3.final.2021', 'checker4.final.2021', 'checker5.final.2021', 'checker6.final.2021'
    <<~POLICY
      path "telegram/data/monitoring" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/index" {
        capabilities = ["read"]
      }

      path "tls/data/certificate/volgactf_final_2021_wan_ecc" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/2021/auth/*" {
        capabilities = ["read"]
      }

      path "volgactf/data/final/2021/flag/sign_key/public" {
        capabilities = ["read"]
      }

      path "docker/data/volgactf" {
        capabilities = ["read"]
      }
    POLICY
  else
    ''
  end
end

def get_token_policy(instance_role_name)
  <<~POLICY
    path "auth/approle/role/#{instance_role_name}/secret-id" {
      capabilities = ["update"]
    }

    path "auth/approle/role/#{instance_role_name}/role-id" {
      capabilities = ["read"]
    }
  POLICY
end

client = ::Vault::Client.new(address: ENV['VAULT_ADDR'], token: ENV['VAULT_TOKEN'])
prefix = 'private'

instances = [
  # 'mars',
  'master.q.dev',
  'master.q.staging',
  'master.q.2022',
  'master.final.dev',
  'checker1.final.dev',
  'checker2.final.dev',
  'master.final.2021',
  'checker1.final.2021',
  'checker2.final.2021',
  'checker3.final.2021',
  'checker4.final.2021',
  'checker5.final.2021',
  'checker6.final.2021'
]

repo_policies = {}
role_policy_bindings = {}
token_info = {}

puts 'Ask whether to create tokens? (yes/no, default: no)'
ask_create_tokens = gets.chomp == 'yes'

instances.each do |instance|
  instance_role_name = get_instance_role_name(prefix, instance)
  instance_policy_name = get_instance_policy_name(prefix, instance)
  token_policy_name = get_token_policy_name(prefix, instance)
  repo_policies[instance_policy_name] = get_instance_policy(prefix, instance)
  repo_policies[token_policy_name] = get_token_policy(instance_role_name)
  role_policy_bindings[instance_role_name] = instance_policy_name
  next unless ask_create_tokens

  puts "Create token for #{instance}? (yes/no, default: no)"
  next if gets.chomp != 'yes'

  token_info[instance] = {
    'approle' => instance_role_name,
    'policy' => token_policy_name
  }
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
    'approle' => val['approle']
  }
  puts "Auth for #{key}\n==========\n#{JSON.pretty_generate(auth_data)}\n==========\n"
end
