#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: beanstalk-val.rb [options]"
  opts.on("-h", "--host HOST", "beanstalk host") do | host|
    options[:host] = host
  end

  opts.on("--port", "--port PORT", "beanstalk port") do | port |
    options[:port] = port
  end

  opts.on("--error", "--error [ERROR_LIMIT]", Integer, "max items in tube before error") do | error_limit|
    options[:error] = error_limit
  end

  opts.on("--warn", "--warn [WARN_LIMIT]", Integer, "max items in tube before warn") do | warn_limit|
    options[:warn] = warn_limit
  end

  opts.on("--tube", "--tube TUBE", "beanstalk tube") do | tube |
    options[:tube] = tube
  end

  opts.on("--stat", "--stat STAT_NAME",  "The name of the statistic") do | stat|
    options[:stat] = stat
  end

end

begin
  optparse.parse!

  mandatory = [:host, :port, :error, :warn, :stat]
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

connection = Beanstalk::Connection.new("#{options[:host]}:#{options[:port]}")

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

status, msg = if val > options[:error]
  [2, "CRITICAL - Too many outstanding #{stat}:  #{val}.  Error limit: #{options[:error]}"]
elsif val > options[:warn]
  [1, "WARNING - Too many outstanding #{stat}:  #{val}.  Warn limit: #{options[:warn]}"]
else
  [0, "OK - #{val} #{stat} found."]
end

puts msg
exit status
