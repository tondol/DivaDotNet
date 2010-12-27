#!/usr/local/bin/ruby
# -*- encoding: utf-8 -*-

require 'kconv'
require 'divadotnet'

ACCESS_CODE = "YOUR_ACCESS_CODE"
PASSWORD = "YOUR_PASSWORD"

diva = DivaDotNet.login(ACCESS_CODE, PASSWORD)
sleep 1
user = diva.get_user
sleep 1
get_song_pages = diva.get_song_pages
sleep 1
song = diva.get_song(get_song_pages.first)

puts user.to_s
puts song.to_s

# on windows:
# puts user.to_s.tosjis
# puts song.to_s.tosjis

# sample output:
# >ruby -v
# ruby 1.9.1p376 (2009-12-07 revision 26041) [i386-mswin32]
# >ruby sample.rb
# {"name"=>"とんどる", "level"=>"Lv 74 メヌエット", "point"=>"862VP", "module"=>"ナチュラ
# ル"}
# {"name"=>"恋は戦争", "thumbnail"=>"/divanet/img/pv/7dfafd6df0889e82", "easy"=>{"difficul
# ty"=>"2", "clear"=>false, "great"=>false, "perfect"=>false, "trial"=>"none", "high_achiv
# ement"=>"0.0%", "high_score"=>"0pts"}, "normal"=>{"difficulty"=>"4", "clear"=>false, "gr
# eat"=>false, "perfect"=>false, "trial"=>"none", "high_achivement"=>"0.0%", "high_score"=
# >"0pts"}, "hard"=>{"difficulty"=>"6", "clear"=>true, "great"=>true, "perfect"=>true, "tr
# ial"=>"clear", "high_achivement"=>"103.88%", "high_score"=>"221990pts"}, "extreme"=>{"di
# fficulty"=>"8", "clear"=>true, "great"=>true, "perfect"=>false, "trial"=>"clear", "high_
# achivement"=>"87.66%", "high_score"=>"294700pts"}, "credit"=>{"作曲者"=>"ryo", "作詞者"=
# >"ryo", "編曲者"=>"ryo", "イラストレーター"=>"三輪士郎"}}
