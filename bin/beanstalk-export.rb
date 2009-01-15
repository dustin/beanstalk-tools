#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

BS=Beanstalk::Connection.new $*.first

def kick(n=10000000)
  BS.kick n
rescue
  # Kick isn't implemented in the current released client.
  BS.send(:interact, "kick #{n}\r\n", %w(KICKED))[0].to_i
end

def export(t)
  loop do
    job = BS.reserve 0

    # Record the time the job should actually start.
    d = Time.now.to_i + job.delay

    puts YAML::dump(:tube => t, :when => d,
                    :pri => job.pri, :ttr => job.ttr,
                    :body => job.body)
    $stdout.flush
    $stderr.puts "Got job #{job.id} (+#{job.delay})"
    job.delete
  end
rescue Beanstalk::TimedOut
  nil
end

stats = BS.stats

if stats["current-workers"] > 0
  $stderr.puts "Warning: There are active workers.  This may go wrong."
end

tubes = BS.list_tubes

tubes.each do |t|
  $stderr.puts "Doing #{t}"
  BS.watch t
  # Stop watching everything but the current.
  BS.list_tubes_watched.reject{|x| x == t}.each{|rt| BS.ignore rt }

  # Kick twice to get all the jobs ready.
  2.times { kick }

  export t
end

stats2 = BS.stats

if stats2["current-jobs-ready"] + stats2["current-jobs-delayed"] +
    stats2["current-jobs-buried"] > 0
  $stderr.puts "There are still jobs after an export."
  $stderr.puts "I'm guessing you weren't in draining mode."
end
