#!/usr/local/bin/ruby
# -*- encoding: utf-8 -*-

require 'kconv'
require 'divadotnet'

ACCESS_CODE = "YOUR_ACCESS_CODE"
PASSWORD = "YOUR_PASSWORD"

# get instance and login
diva = DivaDotNet.login(ACCESS_CODE, PASSWORD)
sleep 1
# get user data
puts "get user data..."
user = diva.get_user
puts user.to_s.tosjis
sleep 1
# you have to get song summaries before getting song data
puts "get song summaries..."
summaries = diva.get_song_summaries
sleep 1
# you have to specify the summary to get song data
summaries.each {|summary|
  name = summary['name']
  puts "get song data (#{name})..."
  puts diva.get_song(summary).to_s
  sleep 1
}
