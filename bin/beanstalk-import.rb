#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

filename = $*.shift

BS=Beanstalk::Connection.new $*.first

f=open filename do |f|
  YAML.each_document(f) do |y|
    args = [:body, :pri, :delay, :ttr].map{|a| y[a]}
    j = BS.put *args
    puts "Placed #{j}"
  end
end

