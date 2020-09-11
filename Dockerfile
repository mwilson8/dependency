FROM cdn-docker.363-283.io/chimera/fast-pymera:v0.2.8

COPY . /usr/src/app
WORKDIR /usr/src/app

ARG CI

ENV CI ${CI}

# pip command
ARG PIP_CMD='pip install --no-cache-dir --use-feature=2020-resolver'

# Alpine package command
ARG APK_ADD='apk add --no-cache'

# development packages that will be installed before pip is run and purged after
ARG DEV_PKGS='libpng-dev \
              make \
              '

RUN $APK_ADD --virtual .build-deps $DEV_PKGS

RUN $PIP_CMD -r requirements.txt

RUN cp /usr/src/app/docker/dependency/ssh/* /root/.ssh && chmod -R 600 /root/.ssh && \
    if test -n "$CI"; then sed -i '/#    Hostname.*/s/^#//' /root/.ssh/config; fi && \
    $PIP_CMD gunicorn && $PIP_CMD uvicorn && \
    rm -r /root/.ssh/id_rsa* && \
    mkdir -p /tmp

ENTRYPOINT ["sh", "/usr/src/app/docker/dependency/docker-entrypoint.sh"]

CMD ["uvicorn", \
    "dependency:app", \
    "--host", "0.0.0.0", \
    "--port", "8000", \
    "--reload-dir", "/usr/src/app/dependency"]
