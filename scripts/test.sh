#!/bin/sh -e
# test.sh --- Tests the project.
#
# GitLab's Environment Variables
# ------------------------------
#
# CI_BUILD_TOKEN:  The build identifier
# CI_PROJECT_DIR:  The project directory
#
# Running Locally
# -----------
#
# To run the tests locally using this script from the project root:
#
#     scripts/test.sh
SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_NAME=dependency

# include common utilities
test -f $SCRIPT_DIR/functions && . $SCRIPT_DIR/functions


# --------------------
# Before Script
# --------------------
export COMPOSE_INTERACTIVE_NO_CLI=1  # configure docker/docker-compose for non-interactive operation
export COMPOSE_PROJECT_NAME=$CI_JOB_ID

start_and_initialize_docker


# --------------------
# Test Script
# --------------------

# 1. Ensure latest docker images
docker-compose pull

# 2. Start up dockerized environment
docker-compose -f docker-compose.yml -f docker-compose.test.yml up --build --no-recreate start-dependencies

# 3. Run automated tests w/coverage
docker-compose exec -T $PROJECT_NAME sh -c 'python3.6 setup.py version && coverage run -m pytest && coverage report -m'

# 4. Run linter
docker-compose exec -T $PROJECT_NAME sh -c 'python3.6 setup.py lint --lint-output-format=text | tee pylint.txt || exit 0'


# --------------------
# After Script
# --------------------
docker-compose down
docker-compose -f docker-compose.yml rm -f start-dependencies  # ensure start-dependencies is removed
