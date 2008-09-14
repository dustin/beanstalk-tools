#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

server = $*[0]
warn_jobs, err_jobs = $*[1..-1].map{|n| n.to_i}

stats = Beanstalk::Connection.new(server).stats

jobs = stats['current-jobs-ready'] + stats['current-jobs-delayed']

status, msg = if jobs > err_jobs
  [2, "Too many outstanding jobs:  #{jobs}.  Error limit: #{err_jobs}"]
elsif jobs > warn_jobs
  [1, "Too many outstanding jobs:  #{jobs}.  Warn limit: #{warn_jobs}"]
else
  [0, "#{jobs} jobs found."]
end

puts msg
exit status
