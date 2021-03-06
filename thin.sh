#!/bin/sh

# set ruby GC parameters
RUBY_HEAP_MIN_SLOTS=600000
RUBY_FREE_MIN=200000
RUBY_GC_MALLOC_LIMIT=60000000
export RUBY_HEAP_MIN_SLOTS RUBY_FREE_MIN RUBY_GC_MALLOC_LIMIT

pid="log/thin.pid"

case "$1" in
  start)
    bundle exec thin start -e development -p 8081 --max-conns 102400 -P $pid -d
    #bundle exec thin start -e production -p 8081 --max-conns 102400 -P $pid -d
    ;;
  stop)
    echo $pid
    bundle exec thin stop -P $pid
    ;;
  force-stop)
    kill -9 `cat $pid`
    ;;		
  restart)
		bundle exec thin restart -P $pid
    ;;
  *)
    echo $"Usage: $0 {start|stop|force-stop|restart}"
    ;;
esac
