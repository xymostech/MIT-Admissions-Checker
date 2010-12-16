require 'rubygems'
require 'httpclient'
require 'pony'

username = "INSERT_YOUR_USERNAME_HERE" # Put your username for decisions.mit.edu here
password = "INSERT_YOUR_PASSWORD_HERE" # Put your password for decisions.mit.edu here

email = "INSERT_YOUR_EMAIL_HERE" # put your password for your gmail account here
email_password = "INSERT_YOUR_EMAIL_PASSWORD_HERE" # put your password for your gmail account here

if(username == "INSERT_YOUR_USERNAME_HERE")
  abort("Read the comments, you need to change your username (or you chose a really bad username)")
elsif(password == "INSERT_YOUR_PASSWORD_HERE")
  abort("Read the comments, you need to change your username (or you chose a really bad password)")
end

use_email = true

if(email == "INSERT_YOUR_EMAIL_HERE" || !(email.match(/\@gmail\.com/)))
  use_email = false
end

def send_email(email, password, message)
  Pony.mail(:to => email, :via => :smtp, :via_options => {
  :address => 'smtp.gmail.com',
  :port => '587',
  :enable_starttls_auto => true,
  :user_name => email,
  :password => password,
  :authentication => :plain
  },
  :subject => 'MIT Admissions Checker Alert!', :body => message)
end

certs='./certs'

nochange = true

orig_redirectcontent = '0;URL=verify.php'
orig_redirecturl = 'verify.php'

orig_textdata = true
orig_texthasconfirmation = true

while(true)
  
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
  
  # Check verify page for changes
  
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
  
  if(!nochange)
    
    # Something has changed, take a few educated guesses...
    
    if(homesource =~ /form(.+)\/form/im)
      
      client.post(home, "username=#{username}&password=#{password}&buttonClick=Confirm") do |data| 
        data =~ /span class="text">(.+)<\/span/im
        
        if($1)
          puts "Found a span in the homepage! Emailing text..."
          if(use_email)
            send_email(email, email_password, "Found a span with the text: \"#{$1}\"")
          end
        else
          
          data.scan(/span class="(\w+)">(.+)<\/span/im) do |spanclass,text|
            if(spanclass != "mit" && spanclass != "ooa")
              puts "Found a span in the homepage! Emailing text..."
              if(use_email)
                send_email(email, email_password, "Found a span with class \"#{spanclass}\" and text: \"#{text}\"")
              end
            end
          end
          
        end
      end
      
    elsif((newredirectsource=client.get_content(home+redirecturl)) =~ /form(.+)\/form/im)
      
      client.post(home+redirecturl, "username=#{username}&password=#{password}&buttonClick=Confirm") do |data| 
        data =~ /span class="text">(.+)<\/span/im
        
        if($1)
          puts "Found a span in the new redirect page! Emailing text..."
          if(use_email)
            send_email(email, email_password, "Found a span with the text: \"#{$1}\"")
          end
        else
          
          data.scan(/span class="(\w+)">(.+)<\/span/im) do |spanclass,text|
            if(spanclass != "mit" && spanclass != "ooa")
              puts "Found a span in the new redirect page! Emailing text..."
              if(use_email)
                send_email(email, email_password, "Found a span with class \"#{spanclass}\" and text: \"#{text}\"")
              end
            end
          end
          
        end
      
    end
    
    if(use_email)
      send_email(email, email_password, "The MIT Admissions Checker found something! Go to decisions.mit.edu to see what happened!")
    end
  end
  
  nochange = true
  
  sleep(300)
end