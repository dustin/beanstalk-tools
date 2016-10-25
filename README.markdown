# Beanstalk Utilities

Here is a small collection of tools for watching, monitoring, and
manipulating beanstalkd.

## Interactive Commands

Interactive commands are in the bin directory.  
Before using below commands make sure to run this command ```sudo gem install  beanstalk-client```.

### beanstalk-stats.rb

beanstalk-stats.rb gives you a feel for how fast things are going in and out
of your queue.

    usage: beanstalk-stats.rb host:11300 host2:11300 [...]

### beanstalk-queue-stats.rb

beanstalk-queue-stats.rb watches a single beanstalk instance and shows you
which tubes contain elements, and how fast they're changing.

    usage: beanstalk-queue-stats.rb host:11300

### beanstalk-cleanup.rb

beanstalk-cleanup.rb is a continuously edited one-off script to help clean
stuff out of queues.  It pulls stuff out of the queue and defers, buries, or
deletes items based on regexes over the content.

    usage: vi beanstalk-cleanup.rb
           # edit the awesome hard-coded bury and delete rules
           beanstalk-cleanup.rb host:11300

### beanstalk-export.rb

beanstalk-export.rb will export all of the jobs from a server.  You
can use it to perform a server upgrade, or migrate all of the jobs
from one server another.

You *should* put the server in draining mode (send signal `USR1`)
before starting this to ensure new jobs aren't getting queued.  You
may also consider shutting down your workers since it may otherwise
cause jobs to be executed prematurely.

Note that the following job attributes are preserved:

* tube
* delay
* priority
* ttr
* body

Anything else (e.g. buried status or number of failures) is lost in
translation.

    usage: beanstalk-export.rb host:11300 > export.yml

### beanstalk-import.rb

beanstalk-import.rb is a tool to complement to beanstalk-export.rb by
allowing the export to be loaded into another server.

    usage: beanstalk-import.rb export.yml host:11300

## Nagios Monitoring Scripts

### beanstalk-jobs.rb

Ensures the number of jobs in the default tube fall within a reasonable range.

    usage: beanstalk-jobs.rb --host localhost --port 11300 --warn 10 --error 20

warn and error respectively set the maximum number of jobs found
before a warning or error is issued. Optionally the --tube argument can be used to restrict 
statistics to a particular tube.

### beanstalk-workers.rb

Ensures that the number of workers within the queue is within range.

    usage: beanstalk-workers.rb  --host localhost --port 11300 --warn 10 --error 5

warn and error respectively specify the minimum workers
that should be in place before a warning or error is issued.
Optionally the --tube argument can be used to restrict 
statistics to a particular tube.

### beanstalk-rate.rb

Ensures the growth rate of a particular stat is within range.

    usage: beanstalk-rate.rb host:11300 --host localhost --port 11300 --warnlow 0.05 --errorlow 0.01   --warnhigh 0.75 --errorhigh 0.99 --stat stat_name

All min and max values are required and are interpreted as floats.  The rates
are expressed as units per second. Optionally the --tube argument can be used to restrict 
statistics to a particular tube.
