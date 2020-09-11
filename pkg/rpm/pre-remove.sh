#!/bin/sh
# pre-remove.sh --- Custom pre-remove script.
APP_NAME=dependency-1.0

[ -f /etc/sysconfig/${APP_NAME} ] && . /etc/sysconfig/${APP_NAME}

echo "Stopping service [$APP_NAME]..."
service ${APP_NAME} stop || true

if [ "$1" = "0" ]; then    # uninstall
  unlink /etc/init.d/${APP_NAME}
  /sbin/chkconfig --del ${APP_NAME} > /dev/null 2>&1
fi

exit 0
