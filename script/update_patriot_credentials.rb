#!/usr/bin/env ruby
# Script to update Patriot persona with Twitter API credentials

persona = Persona.find_by(slug: 'patriot')

if persona.nil?
  puts "❌ Patriot persona not found!"
  exit 1
end

persona.update!(
  twitter_api_key: ENV['X_PATRIOT_API_KEY'],
  twitter_api_secret: ENV['X_PATRIOT_API_SECRET'],
  twitter_access_token: ENV['X_PATRIOT_ACCESS_TOKEN'],
  twitter_access_token_secret: ENV['X_PATRIOT_ACCESS_TOKEN_SECRET'],
  twitter_enabled: true,
  twitter_handle: 'thePatriotViews'
)

puts "✅ Patriot persona updated successfully!"
puts ""
puts "Credentials stored:"
puts "  API Key: #{persona.twitter_api_key[0..10]}..." if persona.twitter_api_key
puts "  API Secret: #{persona.twitter_api_secret[0..10]}..." if persona.twitter_api_secret
puts "  Access Token: #{persona.twitter_access_token[0..20]}..." if persona.twitter_access_token
puts "  Access Token Secret: #{persona.twitter_access_token_secret[0..10]}..." if persona.twitter_access_token_secret
puts "  Twitter Handle: @#{persona.twitter_handle}"
puts "  Twitter Enabled: #{persona.twitter_enabled}"
puts ""
puts "Has all credentials: #{persona.has_twitter_credentials?}"

