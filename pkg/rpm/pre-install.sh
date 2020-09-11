#!/bin/sh
APP_NAME=dependency-1.0
USERNAME=dependency
GROUPNAME=services

[ -f /etc/sysconfig/${APP_NAME} ] && . /etc/sysconfig/${APP_NAME}


# ensure group exists
getent group ${GROUPNAME} >/dev/null || groupadd -f -r ${GROUPNAME}


# ensure user exists
if ! getent passwd ${USERNAME} >/dev/null ; then
    group_id=$(getent group ${GROUPNAME} | cut -d: -f3)
    useradd -r -g "$group_id" -s /sbin/nologin -c "${APP_NAME} service user account." "$USERNAME"
fi

exit 0
