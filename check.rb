require 'httpclient'

uri='https://decisions.mit.edu/'
client = HTTPClient.new()
client.ssl_config.set_trust_ca('./certs')
puts client.get(uri).content