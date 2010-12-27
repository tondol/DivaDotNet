# -*- encoding: utf-8 -*-

require 'net/http'
require 'net/https'
require 'uri'

# HTTP
class Agent
  def initialize
    @last_http = nil
    @last_domain = nil
    @last_port = nil
    @cookies = CookieGroup.new
  end
  
  def set_https(domain, port=443)
    if @last_domain != domain || @last_port != port then
      https = Net::HTTP.new(domain, port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @last_http = https
      @last_domain = domain
      @last_port = port
    end
    @last_http
  end
  
  def set_http(domain, port=80)
    if @last_domain != domain || @last_port != port then
      http = Net::HTTP.new(domain, port)
      @last_http = http
      @last_domain = domain
      @last_port = port
    end
    @last_http
  end
  
  def get(path, header=nil)
    response = nil
    @last_http.start {|w|
      header = Hash.new unless header
      header['cookie'] = @cookies.get_cookie(path)
      response = w.get(path, header)
      response.body.force_encoding('utf-8')
    }
    @cookies.parse(response)
    response
  end
  
  def post(path, data, header=nil)
    response = nil
    @last_http.start {|w|
      header = Hash.new unless header
      header['cookie'] = @cookies.get_cookie(path)
      response = w.post(path, data, header)
      response.body.force_encoding('utf-8')
    }
    @cookies.parse(response)
    response
  end
  
  def build_query(hash)
    queries = []
  	hash.each_pair {|key, value|
      if value.instance_of?(Array) then
        value.each {|v|
          queries << (URI.escape(key) + '[]=' + URI.escape(v))
        }
      else
        queries << (URI.escape(key) + '=' + URI.escape(value))
      end
    }
    queries.join('&')
  end
end
