#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

BS=Beanstalk::Pool.new $*

saw={}

loop do
  job = BS.reserve
  code = case job.ybody
  when Hash
    job.ybody[:code]
  else
    job.ybody.inspect
  end
  if saw[code] && saw[code] != job.id
    puts "Already saw something that looked like #{job.id} (#{code}) (deleting)"
    job.delete
  else
    if code =~ /like.a.chisled.greek.god/
      puts "Burying #{code}"
      job.bury
    elsif code =~ /who.each.posess.the.strength.of.ten.men/
      puts "Deleting #{code}"
      job.delete
    else
      puts "keeping #{job.id} (#{code})"
      job.release(job.pri, 60)
    end
    saw[code] = job.id
  end
end
