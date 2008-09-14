# Beanstalk Utilities

Here is a small collection of tools for watching, monitoring, and
manipulating beanstalkd.

## Interactive Commands

Interactive commands are in the bin directory.

### beanstalk-stats.rb

beanstalk-stats.rb gives you a feel for how fast things are going in and out
of your queue.

    usage: beanstalk-stats.rb host:11300 host2:11300 [...]

### beanstalk-queue-stats.rb

beanstalk-queue-stats.rb watches a single beanstalk instance and shows you
which tubes contain elements, and how fast they're changing.

    usage: beanstalk-queue-stats.rb host:11300
