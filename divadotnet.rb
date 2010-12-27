# -*- encoding: utf-8 -*-

require 'agent'
require 'cookiegroup'

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
    SONG_EASY_REGEXP = /<b>EASY<\/b>/
    SONG_NORMAL_REGEXP = /<b>NORMAL<\/b>/
    SONG_HARD_REGEXP = /<b>HARD<\/b>/
    SONG_EXTREME_REGEXP = /<b>EXTREME<\/b>/
    SONG_CREDIT_REGEXP = /<font[^>]*>作曲者<\/font>/
    SONG_CREDIT_TD_STRING = "<td[^>]*><font[^>]*>([^<]+)<\/font><\/td>"
    SONG_CREDIT_TR_REGEXP = Regexp.new(SONG_CREDIT_TD_STRING * 2)
    
    SONG_DIFFICULTY_REGEXP = /★(\d+)/
    SONG_TRIAL_NONE_REGEXP = /<font[^>]*>NO CLEAR<\/font>/
    SONG_TRIAL_CLEAR_REGEXP = /<font[^>]*>C-TRIAL ○<\/font>/
    SONG_TRIAL_GREAT_REGEXP = /<font[^>]*>G-TRIAL ○<\/font>/
    SONG_TRIAL_PERFECT_REGEXP = /<font[^>]*>P-TRIAL ○<\/font>/
    SONG_HIGH_ACHIVEMENT_REGEXP = /<font[^>]*>(\d+\.\d+%)<\/font>/
    SONG_HIGH_SCORE_REGEXP = /<font[^>]*>(\d+pts)<\/font>/
    
    SONG_PAGES_INDEX_PATH = "/divanet/pv/list/0/0"
    SONG_PAGES_INDEX_PREFIX = "/divanet/pv/list/"
    SONG_PAGES_PREFIX = "/divanet/pv/info/"
    SONG_PAGES_REGEXP = /#{SONG_PAGES_PREFIX}[^"]+/
    SONG_PAGES_INDEX_REGEXP = /#{SONG_PAGES_INDEX_PREFIX}[^"]+/
    
    def initialize
      @agent = Agent.new
    end
    
    def login(access_code, password)
      @agent.set_https(BASE_DOMAIN)
      response = @agent.post(LOGIN_PATH, @agent.build_query({
        'accessCode' => ACCESS_CODE,
        'password' => PASSWORD,
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
    
    def get_song(path)
      # init
      song = Hash.new
      # get
      @agent.set_http(BASE_DOMAIN)
      response = @agent.get(path)
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
      table_keys = [
        'easy', 'normal', 'hard', 'extreme',
      ]
      table_keys.each {|key|
        song[key] = get_song_score(tables.shift)
      }
      song['credit'] = get_song_credit(tables.shift)
      # return
      song
    end
    
    def get_song_pages
      @agent.set_http(BASE_DOMAIN)
      get_song_pages_recursive(SONG_PAGES_INDEX_PATH, [])
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
      # dificulty
      hash['difficulty'] = $1 if table =~ SONG_DIFFICULTY_REGEXP
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
      # highscore
      hash['high_achivement'] = $1 if table =~ SONG_HIGH_ACHIVEMENT_REGEXP
      hash['high_score'] = $1 if table =~ SONG_HIGH_SCORE_REGEXP
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
    def get_song_pages_recursive(index, crawled)
      # search
      response = @agent.get(index)
      body = form_html(response.body)
      song_paths = body.scan(SONG_PAGES_REGEXP)
      index_paths = body.scan(SONG_PAGES_INDEX_REGEXP)
      crawled << index
      # search recursive
      index_paths.each {|path|
        next if crawled.include?(path)
        song_paths += get_song_pages_recursive(path, crawled)
      }
      # return
      song_paths
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
