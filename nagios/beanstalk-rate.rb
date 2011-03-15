#!/usr/bin/env ruby

require 'fileutils'

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
    FileUtils.mkdir_p @dir
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




require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: beanstalk-jobs.rb [options]"
  opts.on("-h", "--host HOST", "beanstalk host") do | host|
    options[:host] = host
  end
  
  opts.on("--port", "--port PORT", "beanstalk port") do | port |
    options[:port] = port
  end
  
  opts.on("--stat", "--stat STAT_NAME",  "The name of the statistic") do | stat|
    options[:stat] = stat
  end

  opts.on("--errorlow", "--errorlow [ERROR_LIMIT]", Float, "Lower error bound for statistic") do | error_limit|
    options[:errorlow] = error_limit
  end
  
  opts.on("--errorhigh", "--errorhigh [ERROR_LIMIT]", Float, "Upper error bound for statistic") do | error_limit|
    options[:errorhigh] = error_limit
  end
  
  opts.on("--warnlow", "--warnlow [WARN_LIMIT]", Float, "Lower warn bound for statistic") do | warn_limit|
    options[:warnlow] = warn_limit
  end
    
  opts.on("--warnhigh", "--warnhigh [WARN_LIMIT]", Float, "Upper warn bound for statistic") do | warn_limit|
    options[:warnhigh] = warn_limit
  end
  
  opts.on("--tube", "--tube TUBE", "beanstalk tube") do | tube |
    options[:tube] = tube 
  end
    
end

begin 
  optparse.parse!

  mandatory = [:host, :port, :stat, :errorlow, :warnlow, :errorhigh, :warnhigh]
  missing = mandatory.select{ |param| options[param].nil? }
  if missing.any?
    puts "Missing options: #{missing.join(', ')}"
    puts optparse
    exit
  end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse 
  exit
end

server = "#{options[:host]}:#{options[:port]}"
connection = Beanstalk::Connection.new(server)


if options[:tube]
  begin
    stats = connection.stats_tube(options[:tube])
  rescue Beanstalk::NotFoundError
    puts "Tube #{options[:tube]} not found." 
    exit
  end
else
 stats = connection.stats
end



stat = options[:stat]
val = stats[stat]

if val.nil?
  puts "No value for stat #{stat}" 
  exit
end

pstat=PersistedStat.new server, stat

rate = pstat.rate(val)

status, msg = if rate.nil?
  [1, "No stored data for #{stat} yet."]
elsif rate < options[:errorlow]
  [2, "#{stat} rate is too low:  #{rate}/s (expected at last #{options[:errorlow]})"]
elsif rate < options[:warnlow]
  [1, "#{stat} rate is too low:  #{rate}/s (want at last #{options[:warnlow]})"]
elsif rate > options[:errorhigh]
  [2, "#{stat} rate is too high:  #{rate}/s (max is #{ options[:errorhigh]})"]
elsif rate > options[:warnhigh]
  [1, "#{stat} rate is too high:  #{rate}/s (warn is #{options[:warnhigh]})"]
else
  [0, "#{stat} rate is #{rate}/s"]
end

pstat.val=val

puts msg
exit status
