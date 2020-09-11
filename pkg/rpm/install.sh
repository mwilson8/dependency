#!/bin/sh
# install.sh --- RPM installation script.
APP_NAME=dependency-1.0
APP_HOME=/opt/services/${APP_NAME}
USERNAME=dependency
GROUPNAME=services


# 0. source environment overrides
[ -f /etc/sysconfig/${APP_NAME} ] && . /etc/sysconfig/${APP_NAME}


# 1. install application dependencies
pip3.6 install --root $RPM_BUILD_ROOT$APP_HOME -e .


# 2. Install dependency
python3.6 setup.py install \
  --single-version-externally-managed \
  -O1 \
  --root=$RPM_BUILD_ROOT$APP_HOME


# 3. install gunicorn && uvicorn
pip3.6 install --root $RPM_BUILD_ROOT$APP_HOME gunicorn
pip3.6 install --root $RPM_BUILD_ROOT$APP_HOME uvicorn


# 4. application configuration
mkdir -p $RPM_BUILD_ROOT$APP_HOME/logs $RPM_BUILD_ROOT$APP_HOME/__pycache__


# 5. capture installed files for inclusion in the RPM
cat <<EOF > INSTALLED_FILES
${APP_HOME}/bin
${APP_HOME}/usr
%config ${APP_HOME}/etc/logging.json
%dir %attr(-, ${USERNAME}, ${GROUPNAME}) %dir ${APP_HOME}/logs
%dir %attr(-, ${USERNAME}, ${GROUPNAME}) %dir ${APP_HOME}/__pycache__
EOF
