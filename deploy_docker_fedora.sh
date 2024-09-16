#!/usr/bin/env bash

# Author: Erik Mason

# Color variables
SUCCESS='\033[0;32m'
WARN='\033[0;31m'
INFO='\033[1;33m'

usage_string="${INFO}$(basename "$0") [-r(emove)] [-h(elp)] [-i(nstall)]"

docker_packages=(
  'docker'
  'docker-client'
  'docker-client-latest'
  'docker-common'
  'docker-latest'
  'docker-latest-logrotate'
  'docker-logrotate'
  'docker-selinux'
  'docker-engine-selinux'
  'docker-engine'
)

check_fedora() {
  if [[ -x /usr/bin/lsb_release ]]; then
    supported_os=false

    if [[ $(lsb_release -si == "Fedora") ]]; then
      supported_os=true
    else
      echo -e "${WARN}Not a Fedora installation. Exiting.."
      exit 1
    fi
  else
    echo -e "${WARN}lsb_release not found."
    exit 1
  fi
}

usage() {
  echo
  echo -e $usage_string
  echo
}

remove() {
  check_fedora

  for pkg in "${docker_packages[@]}"; do
    sudo dnf remove $pkg -y
  done

  if [[ -e /etc/yum.repos.d/docker-ce.repo ]]; then
    echo -e "${INFO}Removing docker-ce repo"
    sudo rm -v /etc/yum.repos.d/docker-ce.repo
  fi

}

install() {

}
