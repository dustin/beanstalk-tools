#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

BS=Beanstalk::Connection.new $*.first

# Some arbitrary number.
# BS.kick 10000000

loop do
  job = BS.reserve

  puts YAML::dump(:delay => job.delay, :pri => job.pri, :ttr => job.ttr, :body => job.body)
  $stdout.flush
  $stderr.puts "Got job #{job.id}"
  job.delete
end
