require 'httpclient'

certs='./certs'

# Check main page for changes

client = HTTPClient.new()
client.ssl_config.set_trust_ca(certs)

uri='https://decisions.mit.edu/'

puts client.get_content(uri)