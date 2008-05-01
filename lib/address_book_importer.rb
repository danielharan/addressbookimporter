require 'rubygems'
require 'mechanize'
require 'cgi'
require 'iconv'

module AddressBookImporter
  VERSION = '0.0.13'

  class EmptyEmailException < Exception ; end
  class LoginErrorException < Exception ; end
  class ParseException < Exception ; end
  
  class Importer
    attr_accessor :contacts, :agent

    def initialize(login, password)
      begin
        @agent = ::WWW::Mechanize.new {|a| a.log = nil }
        #@agent.user_agent = "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)"
        @agent.user_agent = "Mozilla/5.0 (X11; U; Linux i686; en; rv:1.8.1.1) Gecko/20060601 Epiphany/2.16 Firefox/2.0.0.1 (Ubuntu-edgy)"
        p = login(login, password)
        @contacts = fetch_contacts(p)
      rescue Exception => e
        raise ParseException.new("Error parsing website + " + e.to_s + e.backtrace.inspect)
      end
      raise EmptyEmailException if @contacts.empty?
    end

    def login(login, pass)
    end

    def fetch_contacts(page)
    end
  end
  
  class Hotmail < Importer

    attr_accessor :curr_page, :mode, :login_email

    def login(login, password)
      @login_email = login
      page = @agent.get('http://login.live.com/login.srf?id=2')
      form = page.forms.first
      form.fields.find {|f| f.name == 'login'}.value = login
      form.fields.find {|f| f.name == 'passwd'}.value = password
      page = @agent.submit(form, form.buttons.first)
      raise LoginErrorException if page.body.match(/icon_err\.gif/)
      url = page.root.at('script').inner_html.match(%r{(http:[^"]+)})[0]
      p = @agent.get(url) # http://by132w.bay132.mail.live.com/mail/mail.aspx
      p
    end 

    def fetch_contacts(page)
      rval = []
      link = page.links.select{|l|l.href.match(/Inbox/)}.first
      p = @agent.click(link)
      link = page.links.select{|l|l.href.match(/EditMessage/)}.first
      if p.body.match(/NewMessageGo/)
        if (match = p.body.match(/(\/mail\/ApplicationMainReach\.aspx\?Control=EditMessage[^"]+)/))
          p = @agent.get(match[1])
        end
        form = p.forms.first
        form.add_field!('ToContact.x', 9)
        form.add_field!('ToContact.y', 11)   
        p2 = form.submit
        rval = get_email(p2.body)
      else
        p = @agent.click(link)
        rval = get_email(p.body, /([_\-a-z0-9.A-Z]+(%|\\x)40((?:[-a-z0-9]+\.)+[a-z]{2,}))/)
        rval.collect!{|a|a.gsub(/(%40|\\x40)/, '@')}
      end
      rval.reject{|a|a == @login_email}
    end

    protected
    def get_email(body, match_regex = /([_\-a-z0-9.A-Z]+@((?:[-a-z0-9]+\.)+[a-z]{2,}))/)
      rval = []
      while !(match = body.match(match_regex)).nil?
        rval << match[0]
        body = match.post_match
      end
      rval
    end
  end

  class Gmail < Importer
    
    def login(login, password)
      page = @agent.get('https://mail.google.com/?ui=html')
      
      form = page.forms.first
      form.set_fields 'Email' => login, 'Passwd' => password
      form.submit
      
      # follow stupid redirect so cookies are all properly set
      @agent.get @agent.current_page.meta.first.attributes["href"]
      
      raise LoginErrorException if page.uri.to_s =~ /https:\/\/www\.google\.com\/accounts\/ServiceLoginAuth/
      page = @agent.get "http://mail.google.com/mail/?ui=html&zy=n"
      @base = page.uri.to_s.split('?').first
    end

    def fetch_contacts(page)
      contact_page = @agent.get(@base+"?pnl=a&v=cl")
      emails = contact_page.search('td').select{|l|l.inner_html.chomp.split(' ')[0] =~ /([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/}.collect{|k|k.inner_html.chomp.split(' ')[0]}
    end
    
  end

  class Yahoo < Importer
    
    def login(login, password)
      page = @agent.get('https://login.yahoo.com/config/login_verify2?&.src=ym')
      form = page.forms.first
      form.fields.find {|f| f.name == 'login'}.value = login
      form.fields.find {|f| f.name == 'passwd'}.value = Iconv.iconv('latin1', 'utf-8', password)
      page = @agent.submit(form, form.buttons.first)
      raise LoginErrorException if page.body.match(/<div class="yregertxt">/)
      @agent.click(page.links.first)
    end

    def fetch_contacts(page)
      contact_page = @agent.get("http://address.mail.yahoo.com/")
      contact_page.links.select{|l|l.text =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/}.collect{|l|l.text}.uniq
    end
  end
end

