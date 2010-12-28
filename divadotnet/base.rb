# -*- encoding: utf-8 -*-

# DIVA.NET
module DivaDotNet
  
  BASE_DOMAIN = "project-diva-ac.net"
  
  class DivaDotNet::Base
    
    LOGIN_PATH = "/divanet/login/"
    MENU_PATH = "/divanet/menu/"
    
    USER_NAME_REGEXP = /\[プレイヤー名\]<\/font>([^<]+)/
    USER_LEVEL_REGEXP = /\[LEVEL\/RANK\]<\/font>([^<]+)/
    USER_POINT_REGEXP = /\[VOCALOID POINT\]<\/font>([^<]+)/
    USER_MODULE_REGEXP = /\[モジュール\]<\/font><a[^>]+>([^<]+)/
    
    SONG_INFO_REGEXP = /<center>([^<]+)<img src="([^"]+)"\/><\/center>/
    SONG_TABLE_REGEXP = /<table[^>]*>.+?<\/table>/
    SONG_DIFFICULTY_REGEXP = /<font[^>]*><b>([^<]+)<\/b>★(\d+)<\/font>/
    SONG_CREDIT_TD_STRING = "<td[^>]*><font[^>]*>([^<]+)<\/font><\/td>"
    SONG_CREDIT_TR_REGEXP = Regexp.new(SONG_CREDIT_TD_STRING * 2)
    
    SONG_TRIAL_NONE_REGEXP = /<font[^>]*>NO CLEAR<\/font>/
    SONG_TRIAL_CLEAR_REGEXP = /<font[^>]*>C-TRIAL ○<\/font>/
    SONG_TRIAL_GREAT_REGEXP = /<font[^>]*>G-TRIAL ○<\/font>/
    SONG_TRIAL_PERFECT_REGEXP = /<font[^>]*>P-TRIAL ○<\/font>/
    SONG_HIGH_ACHIVEMENT_REGEXP = /<font[^>]*>(\d+\.\d+)%<\/font>/
    SONG_HIGH_SCORE_REGEXP = /<font[^>]*>(\d+)pts<\/font>/
    
    SONG_SUMMARIES_LIST_PATH = "/divanet/pv/list/0/0"
    SONG_SUMMARIES_LIST_PREFIX = "/divanet/pv/list/"
    SONG_SUMMARIES_INFO_PREFIX = "/divanet/pv/info/"
    SONG_SUMMARIES_REGEXP = /<a href="([^"]+)"[^>]*>([^<]+)<\/a>/
    
    def initialize
      @agent = Agent.new
    end
    
    def login(access_code, password)
      @agent.set_https(BASE_DOMAIN)
      response = @agent.post(LOGIN_PATH, @agent.build_query({
        'accessCode' => access_code,
        'password' => password,
      }))
      self
    end
    
    def get_user
      # init
      user = Hash.new
      hash_regexp = {
        'name' => USER_NAME_REGEXP,
        'level' => USER_LEVEL_REGEXP,
        'point' => USER_POINT_REGEXP,
        'module' => USER_MODULE_REGEXP,
      }
      # get menu
      @agent.set_http(BASE_DOMAIN)
      response = @agent.get(MENU_PATH)
      body = form_html(response.body)
      # eval regexp
      hash_regexp.each_pair {|key, value|
        if body =~ value then
          user[key] = $1
        else
          raise "User information is missing (#{key})"
        end
      }
      # return
      user
    end
    
    def get_song(anchor)
      # init
      song = Hash.new
      # get
      @agent.set_http(BASE_DOMAIN)
      response = @agent.get(anchor['href'])
      body = form_html(response.body)
      tables = body.scan(SONG_TABLE_REGEXP)
      # info
      if body =~ SONG_INFO_REGEXP then
        song['name'] = $1
        song['thumbnail'] = $2
      else
        raise "Song information is missing"
      end
      # score, credit
      tables.each {|table|
        parsed = nil
        if table =~ SONG_DIFFICULTY_REGEXP then
          key = $1.downcase
          difficulty = $2.to_i
          song[key] = get_song_score(table)
          song[key]['difficulty'] = difficulty
        else
          # the implementation of this function is imcomplete
          # song['credit'] = get_song_credit(table)
        end
      }
      # return
      song
    end
    
    def get_song_summaries
      @agent.set_http(BASE_DOMAIN)
      get_song_summaries_recursive(SONG_SUMMARIES_LIST_PATH, [])
    end
    
    private
    def get_song_score(table)
      # init
      hash = Hash.new
      clear_image = {
        'clear' => "/divanet/top/img/clear1.jpg",
        'great' => "/divanet/top/img/clear2.jpg",
        'perfect' => "/divanet/top/img/clear3.jpg",
      }
      trial_regexp = {
        'none' => SONG_TRIAL_NONE_REGEXP,
        'clear' => SONG_TRIAL_CLEAR_REGEXP,
        'great' => SONG_TRIAL_GREAT_REGEXP,
        'perfect' => SONG_TRIAL_PERFECT_REGEXP,
      }
      # clear
      clear_image.each_pair {|key, image|
        hash[key] = table.include?(image)
      }
      # trial
      trial_regexp.each_pair {|key, value|
        if table =~ value then
          hash['trial'] = key
          break
        end
      }
      # high score
      hash['high_achivement'] = $1.to_f if table =~ SONG_HIGH_ACHIVEMENT_REGEXP
      hash['high_score'] = $1.to_i if table =~ SONG_HIGH_SCORE_REGEXP
      # return
      hash
    end
    
    private
    def get_song_credit(table)
      hash = Hash.new
      matches = table.scan(SONG_CREDIT_TR_REGEXP)
      matches.each {|match|
        key = match.shift
        value = match.shift
        hash[key] = value
      }
      hash
    end
    
    private
    def get_song_summaries_recursive(current, crawled)
      # init
      song_summaries = []
      list_hrefs = []
      # search
      response = @agent.get(current)
      body = form_html(response.body)
      # scanning anchors
      body.scan(SONG_SUMMARIES_REGEXP).each {|match|
        href = match.shift
        name = match.shift
        if href.include?(SONG_SUMMARIES_INFO_PREFIX) then
          song_summaries << {
            'name' => name,
            'href' => href,
          }
        elsif href.include?(SONG_SUMMARIES_LIST_PREFIX) then
          list_hrefs << href
        end
      }
      crawled << current
      # search recursive
      list_hrefs.each {|href|
        next if crawled.include?(href)
        song_summaries += get_song_summaries_recursive(href, crawled)
      }
      # return
      song_summaries
    end
    
    private
    def form_html(body)
      # suited for html including error
      body.split("\n").collect {|line|
        $1 if line =~ /^\s*(.*?)\s*$/
      }.join.gsub(/<\/?br>/, '')
    end
  end
  
  def DivaDotNet.login(access_code, password)
    instance = DivaDotNet::Base.new
    instance.login(access_code, password)
    instance
  end
end
