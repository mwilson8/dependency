#!/bin/sh
# dependency.sh --- start/stop script for the dependency based on https://gist.github.com/yin8086/4131895.
# chkconfig: 2345 55 45
# description: start or stop dependency
# chkconfig –add gunicorn in RPM-based distributions
# update-rc.d gunicorn defaults in Debian-based distributions

### BEGIN INIT INFO
# Provides: dependency 1.0
# Required-Start: $all
# Required-Stop: $all
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start the dependency w/ gunicorn
# Description: Starts the dependency w/ gunicorn using start-stop-daemon
### END INIT INFO

APP_HOME=/opt/services/dependency-1.0
DESC="dependency 1.0"
PATH=$APP_HOME/bin:$APP_HOME/usr/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=$APP_HOME/usr/bin/gunicorn
NAME=dependency-1.0
USER=dependency
GROUP=services
GRACEFUL_TIMEOUT=10
PIDFILE=$APP_HOME/logs/$NAME.pid
LOG_LEVEL=info

# ensure application module can be found on Python's path
PYTHONPATH=$APP_HOME/usr/lib/python3.6/site-packages:$APP_HOME/usr/lib64/python3.6/site-packages

export PYTHONPATH

# Source function library.
. /etc/rc.d/init.d/functions

test -x $DAEMON || exit 0

sleep_if_running() {
  PID=$1
  STATE=$(ps -p "$PID" -o s=)
  if [ "$STATE" ] && [ "$STATE" != 'Z' ]; then
      echo "Waiting $2 seconds for termination..."
      sleep "$2"
  fi
  NEWSTATE=$(ps -p "$PID" -o s=)
  if [ "$NEWSTATE" ] && [ "$NEWSTATE" != 'Z' ]; then
      return 1
  else
      return 0
  fi
}

start() {
  action "Starting $DESC" cd "$APP_HOME" && $DAEMON \
    --bind 0.0.0.0:8000 \
    --user $USER \
    --group $GROUP \
    --graceful-timeout $GRACEFUL_TIMEOUT \
    --workers 1 \
    --threads 4 \
    --daemon \
    --pythonpath $PYTHONPATH \
    --log-level $LOG_LEVEL \
    --access-logfile $APP_HOME/logs/access.log \
    --error-logfile $APP_HOME/logs/error.log \
    --pid $PIDFILE \
    --worker-class uvicorn.workers.UvicornWorker \
    dependency:app
}

stop() {
  if [ -f $PIDFILE ]; then
    APP_PID=$(cat $PIDFILE)
    echo "Stopping $DESC "
    kill "$APP_PID" && sleep_if_running "$APP_PID" $((GRACEFUL_TIMEOUT + 1))
    RETVAL=$?
    [ $RETVAL -eq 0 ] && action "Stopped." && return 0
    [ $RETVAL -ne 0 ] && failure && echo "Failed to stop. Kill manually." && return 1
  else
    action "$DESC is already stopped"
  fi
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    if [ -f $PIDFILE ]; then
      APP_PID=$(cat $PIDFILE)
      APP_RUNNING=`ps -p $APP_PID | sed -n '1!p' | wc -l`
      if [ "$APP_RUNNING" -gt "0" ]; then
         echo "$DESC is running ($APP_PID)."
         exit 0
       else
         echo "$DESC has a stale pid ($APP_PID). Removing $PIDFILE."
         rm -f $PIDFILE
         echo "$DESC is not running."
         exit 1
      fi
     else
      echo "$DESC is not running."
      exit 1
    fi
    ;;
  restart)
    echo "Restarting $DESC"
    stop && start
    ;;
  *)
    N=/etc/init.d/$NAME
    echo "Usage: $N {start|stop|restart|status}" >&2
    exit 1
    ;;
esac
exit 0
