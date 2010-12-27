# -*- encoding: utf-8 -*-

# Cookie
class CookieGroup
  def initialize
    @cookies = []
  end
  
  def parse(response)
    # split fields
    return nil unless response['set-cookie']
    array = response['set-cookie'].split(/,/) 
    # process each field
    array.each {|value|
      cookie = Hash.new
      # name, value
      if value =~ /(?:^|\s)([^=]+)=([^;]+)(?:$|;)/ then
        cookie['name'] = $1
        cookie['value'] = $2
      else
        raise "Set-Cookie Header Error"
      end
      # path
      if value =~ /(?:^|\s)Path=([^;]+)(?:$|;)/ then
        cookie['path'] = $1
      end
      # check duplication
      @cookies.each {|old_cookie|
        next if old_cookie['name'] == cookie['name']
      }
      @cookies << cookie
    }
  end
  
  def get_cookie(path)
    queries = []
    @cookies.each {|cookie|
      regexp = Regexp.new('^' + cookie['path'])
      queries << (cookie['name'] + '=' + cookie['value'])if path =~ regexp
    }
    queries.join(' ;')
  end
  
  attr_reader :path, :body
end
