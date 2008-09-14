#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

server = $*[0]
warn_workers, err_workers = $*[1..-1].map{|n| n.to_i}

stats = Beanstalk::Connection.new(server).stats

workers = stats['current-workers']

status, msg = if workers < err_workers
  [2, "Required at least #{err_workers} workers.  Have #{workers}"]
elsif workers < warn_workers
  [1, "Wanted at least #{warn_workers} workers.  Have #{workers}"]
else
  [0, "#{workers} workers found."]
end

puts msg
exit status
