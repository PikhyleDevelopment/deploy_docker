#!/usr/bin/env bash

# Author: Erik Mason

################# Description ###################
#                                               #
#                                               #
#   Deploys Docker Engine to Debian-based linux #
#     distributions.                            #
#                                               #
#################################################

# Color variables
SUCCESS='\033[0;32m' # Green
WARN='\033[0;31m'    # Red
INFO='\033[1;33m'    # Yellow

usage_string="${INFO}$(basename "$0") [-r(emove)] [-h(elp)] [-i(nstall)]"

codenames=(
  'noble'
  'jammy'
  'focal'
)

docker_packages=(
  'docker.io'
  'docker-doc'
  'docker-compose'
  'docker-comose-v2'
  'podman-docker'
  'containerd'
  'runc'
  'docker-ce'
  'docker-ce-cli'
  'containerd.io'
  'docker-buildx-plugin'
  'docker-compose-plugin'
)

usage() {
  echo -e $usage_string
}

remove() {
  # Uninstall docker engine binaries
  for pkg in "${docker_packages[@]}"; do
    sudo apt remove $pkg
  done
}

install() {
  sudo apt update
  sudo apt install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc]\
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt update
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo docker run hello-world
}

while getopts 'hir' flag; do
  case "$flag" in
  h)
    usage
    exit 2
    ;;
  i) install ;;
  r) remove ;;
  ?)
    usage
    exit 2
    ;;
  esac
done
