#!/bin/sh
# post-install.sh --- RPM post-install script.
APP_NAME=dependency-1.0
APP_HOME=/opt/services/${APP_NAME}
USERNAME=dependency
GROUPNAME=services


[ -f /etc/sysconfig/${APP_NAME} ] && . /etc/sysconfig/${APP_NAME}

LOG_FILE="${LOG_FILE:=$APP_HOME/logs/$APP_NAME.log}"
LOG_LEVEL_ROOT=${LOG_LEVEL_ROOT:=WARNING}

# configure logging
mkdir -p `dirname $LOG_FILE`
sed -i \
    -e "/\"root\"/,/}/s/INFO/${LOG_LEVEL_ROOT}/" \
    -e "/\"FileHandler\"/,/}/s|dependency.log|${LOG_FILE}|" \
    $APP_HOME/etc/logging.json

# ensure scripts are executable
if [ -d ${APP_HOME}/bin ]; then
  for script in $APP_HOME/bin/*.sh; do
    chmod +x $script
  done
fi

# configure init script
if [ -f ${APP_HOME}/bin/dependency.sh ]; then
  mkdir -p /etc/init.d

  # configure dependency
  ln -s ${APP_HOME}/bin/dependency.sh /etc/init.d/${APP_NAME}
  chown -h ${USERNAME}:${GROUPNAME} /etc/init.d/${APP_NAME}

fi

# Chown to the correct user
chown -R ${USERNAME}:${GROUPNAME} ${APP_HOME}

# add to system start/stop
/sbin/chkconfig --add ${APP_NAME}

