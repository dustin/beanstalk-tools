#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

filename = $*.shift

BS=Beanstalk::Connection.new $*.first

f=open filename do |f|
  YAML.each_document(f) do |y|
    BS.use y[:tube]
    body, pri, t, ttr = [:body, :pri, :when, :ttr].map{|a| y[a]}

    delay = [0, t - Time.now.to_i].max

    j = BS.put body, pri, delay, ttr

    puts "Placed #{j} (+#{delay})"
  end
end
