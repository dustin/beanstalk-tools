#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

BS=Beanstalk::Pool.new $*

saw={}

def abbrev(code, to=70)
  if code.length > to
    code.slice(0, to-3) + "..."
  else
    code
  end
end

loop do
  job = BS.reserve
  code = case job.ybody
  when Hash
    job.ybody[:code]
  else
    job.ybody.inspect
  end
  s = abbrev(code)
  if saw[code] && saw[code] != job.id
    puts "Already saw something that looked like #{job.id} (#{s}) (deleting)"
    job.delete
  else
    if code =~ /like.a.chisled.greek.god/
      puts "Burying #{s}"
      job.bury
    elsif code =~ /who.each.posess.the.strength.of.ten.men/
      puts "Deleting #{s}"
      job.delete
    else
      puts "keeping #{job.id} (#{s})"
      job.release(job.pri, 60)
    end
    saw[code] = job.id
  end
end
