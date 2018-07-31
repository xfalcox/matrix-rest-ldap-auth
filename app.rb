require 'sinatra'
require 'sinatra/json'
require 'json'
require 'net-ldap'
require 'pry'

post '/_matrix-internal/identity/v1/check_credentials' do
  json = JSON.parse request.body.read

  matrix_user = json['user']['id']
  ldap_user = matrix2ldap(matrix_user)
  password = json['user']['password']

  ldap = Net::LDAP.new
  ldap.host = ENV['LDAP_HOST']
  ldap.port = 389

  puts "Trying to log #{ldap_user} on #{ENV['LDAP_HOST']}"

  ldap.auth ldap_user, password

  halt 403 unless ldap.bind

  entry = ldap.search base: ldap_user

  halt 403 if entry.empty?

  json ldap2response(entry.first)
end

def matrix2ldap(matrix_id)
  localpart = matrix_id.split(':').first.delete_prefix('@')
  "uid=#{localpart},#{ENV['LDAP_BASE']}"
end

def ldap2response(entry)
  hash = template

  hash[:auth][:mxid] = "@#{entry.uid.first}:#{ENV['HOMESERVER_HOST']}"
  hash[:auth][:profile][:display_name] = entry.displayname.first
  hash[:auth][:profile][:avatar_url] = avatar(entry)
  hash[:auth][:profile][:three_pids][0][:address] = entry.mail.first
  hash
end

def template
  {
    auth: {
      success: true,
      mxid: '@matrix.id.of.the.user:example.com',
      profile: {
        display_name: 'John Doe',
        avatar_url: 'http://example.com/avatar',
        three_pids: [
          {
            medium: 'email',
            address: 'john.doe@example.org'
          }
        ]
      }
    }
  }
end

def avatar(entry)
  "#{ENV['AVATAR_URL']}#{entry.uid.first.upcase}"
end
