#!/bin/bash

containers_for_yarn_install=(
  service-name
)

usage () {
  echo "usage: $0 [-cgisBDMN]"
  echo "  This script will set up your development environment and get it"
  echo "  ready to run. It can also be used to reset things after you"
  echo "  screw something up and want to start from a clean slate."
  echo
  echo "  -c clean (delete) node_modules before running yarn install"
  echo "  -B skip build step"
  echo "  -N skip yarn install steps"
  echo
}

while getopts ":cBN" opt; do
  case "$opt" in
    c)
      clean=yep
      ;;
    B)
      skip_build=yep
      ;;
    N)
      skip_yarn_install=yep
      ;;
    \?)
      usage
      exit 1
      ;;
  esac
done

do_yarn_install () {
  # if ! check_github_npm_token; then
  #   return 1
  # fi

  # set up node modules (from scratch)
  for svc in "${containers_for_yarn_install[@]}"; do
    if [[ $clean == "yep" ]]; then
      docker-compose run --rm --no-deps "$svc" rm -rf node_modules
    fi
    if [[ $skip_yarn_install != "yep" ]]; then
      # make sure "node" user has write access to node_modules volume
      # (services run as node user instead of root)
      docker-compose run --rm --no-deps -u root $svc chown node node_modules
      echo "Doing yarn install for $svc."
      docker-compose run --rm --no-deps $svc yarn install
      echo
    fi
  done
}

do_docker_build () {
  local my_uid=$(id -u)
  echo "Building docker containers..."
  docker-compose build --build-arg "NODE_UID=${my_uid}"
}

do_build () {
  echo "Building service-name..."
  docker-compose run --rm --no-deps service-name yarn build
}

### MAIN ###

cd "$PROJDIR"

env_setup "$envfile"

if [[ $skip_build != "yep" ]]; then
  do_docker_build
fi

if ! do_yarn_install; then
  die
fi

if [[ $skip_build != "yep" ]]; then
  do_build
fi