#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

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
  
  opts.on("--error", "--error [ERROR_LIMIT]", Integer, "Required number of workers") do | error_limit|
    options[:error] = error_limit
  end
  
  opts.on("--warn", "--warn [WARN_LIMIT]", Integer, "Desired number of workers") do | warn_limit|
    options[:warn] = warn_limit
  end  
  
  opts.on("--tube", "--tube TUBE", "beanstalk tube") do | tube |
    options[:tube] = tube 
  end
    
end

begin 
  optparse.parse!

  mandatory = [:host, :port, :error, :warn]
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

workers = stats['current-workers']
workers =  workers ?  workers : 0 

status, msg = if workers < options[:error]
  [2, "CRITICAL - Required at least #{options[:error]} workers.  Have #{workers}"]
elsif workers < options[:warn]
  [1, "WARNING - Wanted at least #{options[:warn]} workers.  Have #{workers}"]
else
  [0, "OK - #{workers} workers found."]
end

puts msg
exit status
