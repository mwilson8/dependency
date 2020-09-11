#!/bin/sh
# docker-entrypoint.sh --- Entrypoint for dependency Docker image.


# create version.json
python setup.py version > /dev/null 2>&1

count=0
maxTries=20
printf 'Waiting for AAC ...' >&2
until curl --output /dev/null --silent --head --fail http://cte-aac-service:9991/health; do
  count=$((count+1)) && [ ${count} -eq ${maxTries} ] && printf ' failed after %d tries\n' "$count" >&2 && exit 1
  printf '.' >&2
  sleep 1
done

printf ' done\n' >&2


# execute CMD
if [ -z "$DIR_TO_RELOAD" ]; then
  exec "$@"
else
  exec "$@" "--reload" "--reload-dir" "$DIR_TO_RELOAD"
fi