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
  'docker-compose-v2'
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
  echo -e "${INFO}Removing docker binaries, gpg key, and apt list."
  # Uninstall docker engine binaries
  for pkg in "${docker_packages[@]}"; do
    sudo apt remove $pkg -y
  done

  if [ -e /etc/apt/sources.list.d/docker.list ]; then
    sudo rm -v /etc/apt/sources.list.d/docker.list
  else
    echo "${INFO}Docker apt list not found.. skipping"
  fi

  if [ -e /etc/apt/keyrings/docker.asc ]; then
    sudo rm -v /etc/apt/keyrings/docker.asc
  else
    echo "${INFO}Docker gpg key not found.. skipping"
  fi

  echo -e "${INFO}Successfully cleaned up."
  exit 0
}

install() {
  sudo apt update
  sudo apt install ca-certificates curl -y
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  if [ -e /etc/apt/keyrings/docker.asc ]; then
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc]\
      https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
  else
    echo "${WARN}Docker gpg key not found.. Exiting"
    exit 1
  fi

  echo -e "${SUCCESS}Docker successfully installed. Running hello-world.."

  sudo docker run hello-world

  exit 0
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
