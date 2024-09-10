#!/usr/bin/env bash

# Author: Erik Mason

################# Description ###################
#                                               #
#                                               #
#   Deploys Docker Engine to Ubuntu-based linux #
#     distributions.                            #
#                                               #
#################################################

# Color variables
SUCCESS='\033[0;32m' # Green
WARN='\033[0;31m'    # Red
INFO='\033[1;33m'    # Yellow

usage_string="${INFO}$(basename "$0") [-r(emove)] [-h(elp)] [-i(nstall)]"

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

check_codenames () {
    codenames=(
        "focal"
        "jammy"
        "noble"
    )

    if [[ -x /usr/bin/lsb_release ]]; then

        supported_os=0

        for codename in "${codenames[@]}"; do
            if [[ $codename == $(lsb_release -sc) ]]; then
                supported_os=1
                break
            else
                supported_os=0
            fi
        done

        if [[ ! $supported_os == 1 ]]; then
            echo -e "${WARN}Unsupported OS. Only supports ${codenames[@]}"
            exit 2
        fi
        
    else
        echo -e "${WARN}lsb_release is not found.. Exiting.."
        exit 2
    fi
}

usage() {
  echo -e $usage_string
}

remove() {
  check_codenames

  echo -e "${INFO}Removing docker binaries, gpg key, and apt list."
  # Uninstall docker engine binaries
  for pkg in "${docker_packages[@]}"; do
    sudo apt remove $pkg -y
  done

  if [ -e /etc/apt/sources.list.d/docker.list ]; then
    sudo rm -v /etc/apt/sources.list.d/docker.list
  else
    echo -e "${INFO}Docker apt list not found.. skipping"
  fi

  if [ -e /etc/apt/keyrings/docker.asc ]; then
    sudo rm -v /etc/apt/keyrings/docker.asc
  else
    echo -e "${INFO}Docker gpg key not found.. skipping"
  fi

  echo -e "${INFO}Successfully cleaned up."
  exit 0
}

install() {
  check_codenames

  echo
  echo -e "${INFO}Updating and installing ca-certificates and curl"
  echo
  sudo apt update
  sudo apt install ca-certificates curl -y
  echo
  echo -e "${INFO}Setting up Docker GPG key"
  echo
  sudo install -m 0755 -d /etc/apt/keyrings

  if [[ ! -e /etc/apt/keyrings/docker.asc ]]; then
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc]\
      https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo chmod a+r /etc/apt/keyrings/docker.asc
    sudo apt update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
  else
    echo -e "${WARN}Docker gpg key not found.. Exiting"
    exit 1
  fi

  echo
  echo -e "${INFO}Updating repositories and installing docker binaries.."
  echo

  sudo apt update
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

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
