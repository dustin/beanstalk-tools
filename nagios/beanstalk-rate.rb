#!/usr/bin/env ruby

require 'ftools'

require 'rubygems'
require 'beanstalk-client'

class PersistedStat

  attr_reader :host, :stat_name, :val, :timestamp

  def initialize(host, stat_name, path="/var/tmp/beanstalk_stat")
    f=nil
    @host=host
    @stat_name=stat_name

    @dir=File.join(path, host.gsub(/:/, '_'))
    @filename=File.join(@dir, stat_name)

    @timestamp=File.stat(@filename).mtime
    f=open(@filename)
    @val=f.readline.strip.to_f
  rescue Errno::ENOENT
    # No current data
  ensure
    f.close if f
  end

  def val=(newval)
    File.makedirs @dir
    f=open(@filename, "w")
    f.write("#{newval}\n")
    @val=newval
    @timestamp=Time.now
  ensure
    f.close if f
  end

  def age
    Time.now - @timestamp if @timestamp
  end

  def rate(v)
    (v - @val) / age if @timestamp
  end

end

### Main starts here

server, stat = $*[0..1]
low_err, low_warn, high_warn, high_err = $*[2..-1].map{|n| n.to_f}

stats = Beanstalk::Connection.new(server).stats

val=stats[stat]

pstat=PersistedStat.new server, stat

rate = pstat.rate(val)

status, msg = if rate.nil?
  [1, "No stored data for #{stat} yet."]
elsif rate < low_err
  [2, "#{stat} rate is too low:  #{rate}/s (expected at last #{low_err})"]
elsif rate < low_warn
  [1, "#{stat} rate is too low:  #{rate}/s (want at last #{low_warn})"]
elsif rate > high_err
  [2, "#{stat} rate is too high:  #{rate}/s (max is #{high_err})"]
elsif rate > high_warn
  [1, "#{stat} rate is too high:  #{rate}/s (warn is #{high_warn})"]
else
  [0, "#{stat} rate is #{rate}/s"]
end

pstat.val=val

puts msg
exit status
