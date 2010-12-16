require 'httpclient'

certs='./certs'

nochange = true

orig_redirectcontent = '0;URL=verify.php'
orig_redirecturl = 'verify.php'

# Check main page for changes

client = HTTPClient.new()
client.ssl_config.set_trust_ca(certs)

home='https://decisions.mit.edu/'

homesource = client.get_content(home)

homesource =~ /CONTENT="(\S+)"/i
redirectcontent = $1
redirectcontent =~ /URL=(\S+)/
redirecturl = $1

if(redirectcontent != orig_redirectcontent)
  nochange = false
  orig_redirectcontent = redirectcontent
end

if(redirecturl != orig_redirecturl)
  nochange = false
  orig_redirecturl = redirecturl
end