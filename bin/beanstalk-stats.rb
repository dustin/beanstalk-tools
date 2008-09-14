#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

def delta(ov, nv)
  sym = nv > ov ? "+" : ""
  fmt = nil
  if ov.is_a?(Fixnum)
    fmt = "(%s%d)"
  elsif ov.is_a?(Float)
    fmt = "(%s%.4f)"
  else
    nil
  end

  if fmt
    sprintf fmt, sym, (nv - ov)
  end
end

def show_stats(oldstats, bp)
  s = bp.stats
  puts "----------- #{Time.now} -----------"
  s.keys.sort.each do |k|
    if oldstats[k]
      if oldstats[k] != s[k]
        puts "#{k} = #{s[k]} #{delta oldstats[k], s[k]}"
      end
    else
      puts "#{k} = #{s[k]}"
    end
  end
  s
end

bp = Beanstalk::Pool.new $*
oldstats = {}

loop do
  oldstats = show_stats(oldstats, bp)
  sleep 10
end
