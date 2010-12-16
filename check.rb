require 'httpclient'

certs='./certs'

username = "INSERT_YOUR_USERNAME_HERE"
password = "INSERT_YOUR_PASSWORD_HERE"

nochange = true

orig_redirectcontent = '0;URL=verify.php'
orig_redirecturl = 'verify.php'

orig_textdata = true
orig_texthasconfirmation = true

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
  puts "Found change in redirect content"
  nochange = false
  orig_redirectcontent = redirectcontent
end

if(redirecturl != orig_redirecturl)
  puts "Found change in redirect url"
  nochange = false
  orig_redirecturl = redirecturl
end

verify='https://decisions.mit.edu/verify.php'

client.post(verify, "username=#{username}&password=#{password}&buttonClick=Confirm") do |data| 
  data =~ /span class="text">(.+)<\/span>/im
  textdata = $1
  texthasconfirmation = textdata.match(/confirmed your ability/i)
  
  if(!!textdata ^ orig_textdata)
    puts "Found change in text span existence"
    nochange = false
    orig_textdata = !!textdata
  end
  
  if(!!texthasconfirmation ^ orig_texthasconfirmation)
    puts "Found change in text span content"
    nochange = false
    orig_texthasconfirmation = !!texthasconfirmation
  end
end