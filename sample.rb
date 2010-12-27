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

puts user.to_s.tosjis
puts song.to_s.tosjis
