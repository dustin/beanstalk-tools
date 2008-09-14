#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

B = Beanstalk::Connection.new $*[0]

tubes = $*[1..-1]
tubes = B.list_tubes if tubes.empty?

def delta(v)
  v.to_i > 0 ? "+#{v}" : v.to_s
end

previously={}

loop do
  puts "#{Time.now.to_s}"
  tubes.each do |tube|
    puts "#{tube}"
    ts=B.stats_tube tube
    ts.delete('name')
    deltas = previously[tube] || Hash.new(0)
    ts.keys.sort.each do |k|
      puts " - #{k} = #{ts[k]} (#{delta(ts[k] - deltas[k])})"
    end
    previously[tube] = ts
  end
  puts "------------------"
  sleep 10
end
