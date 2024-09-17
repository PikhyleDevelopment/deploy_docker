#!/usr/bin/env bash

# Author: Erik Mason

# Color variables
SUCCESS='\033[0;32m'
WARN='\033[0;31m'
INFO='\033[1;33m'
CLEAR='\033[0m'

usage_string="${INFO}$(basename "$0") [-r(emove)] [-h(elp)] [-i(nstall)]"

docker_packages_remove=(
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
  'docker-ce'
  'docker-ce-cli'
  'containerd.io'
  'docker-buildx-plugin'
  'docker-compose-plugin'
)

docker_install_packages=(
  'docker-ce'
  'docker-ce-cli'
  'containerd.io'
  'docker-buildx-plugin'
  'docker-compose-plugin'
)

echo '
  ######                                                               
  #     #  ####   ####  #    # ###### #####                            
  #     # #    # #    # #   #  #      #    #                           
  #     # #    # #      ####   #####  #    #                           
  #     # #    # #      #  #   #      #####                            
  #     # #    # #    # #   #  #      #   #                            
  ######   ####   ####  #    # ###### #    #                           
                                                                      
  ######                                                               
  #     # ###### #####  #       ####  #   # #    # ###### #    # ##### 
  #     # #      #    # #      #    #  # #  ##  ## #      ##   #   #   
  #     # #####  #    # #      #    #   #   # ## # #####  # #  #   #   
  #     # #      #####  #      #    #   #   #    # #      #  # #   #   
  #     # #      #      #      #    #   #   #    # #      #   ##   #   
  ######  ###### #      ######  ####    #   #    # ###### #    #   #   
                                                                      
'

check_fedora() {
  if [[ -x /usr/bin/lsb_release ]]; then
    supported_os=false

    if [[ $(lsb_release -si == "Fedora") ]]; then
      supported_os=true
    else
      echo -e "${WARN}Not a Fedora installation. Exiting..${CLEAR}"
      exit 1
    fi
  else
    echo -e "${WARN}lsb_release not found.${CLEAR}"
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

  sudo systemctl disable --now docker.service

  for pkg in "${docker_packages_remove[@]}"; do
    sudo dnf remove $pkg -y
  done

  if [[ -e /etc/yum.repos.d/docker-ce.repo ]]; then
    echo
    echo -e "${INFO}Removing docker-ce repo${CLEAR}"
    echo
    sudo rm -v /etc/yum.repos.d/docker-ce.repo
  fi

  echo
  echo -e "${INFO}Please manually remove the GPG key if desired using: "
  echo

  echo -e '$ sudo rpm -q gpg-pubkey --qf "%{NAME}-%{VERSION}-%{RELEASE} %{SUMMARY}\\n" | grep docker'
  echo -e "$ sudo rpm -e [gpg-pubkey]${CLEAR}"
  echo
}

install() {

  check_fedora

  # Check for existence of dnf-plugins-core package
  if [[ ! $(dnf --installed list | grep dnf-plugins-core) == 0 ]]; then
    sudo dnf -y install dnf-plugins-core
  fi

  # Check for existence of docker repo
  if [[ -e /etc/yum.repos.d/docker-ce.repo ]]; then
    echo
    echo -e "${INFO}Docker repo already setup.. continuing${CLEAR}"
    echo
  else
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  fi

  # Verify docker repo setup correctly
  if [[ ! -e /etc/yum.repos.d/docker-ce.repo ]]; then
    echo
    echo -e "${WARN}Docker repo setup failed.. exiting${CLEAR}"
    echo
    exit 1
  else
    echo
    echo -e "${SUCCESS}Docker repo setup successfully${CLEAR}"
    echo
  fi

  # Install docker packages
  echo
  echo -e "${INFO}Downloading and installing docker packages. Please manually verify the GPG key.${CLEAR}"
  echo

  sudo dnf -y install docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  echo
  echo -e "${INFO}Enabling and starting docker.service${CLEAR}"
  echo

  sudo systemctl enable --now docker

  if [[ -x /usr/bin/docker ]]; then
    echo
    echo -e "${SUCCESS}Docker successfully installed. Running hello-world${CLEAR}"
    echo
  else
    echo
    echo -e "${WARN}Docker binary not found in /usr/bin/.. exiting${CLEAR}"
    echo
    exit 1
  fi
  # Start the docker service and run hello-world

  # systemctl's "is-active" option returns 0 if the service is active.
  # Since 0 is interpreted as false, we negate the check.
  if [[ ! $(systemctl is-active --quiet "docker.service") ]]; then
    echo
    echo -e "${SUCCESS}Docker service is running.${CLEAR}"
    echo

    sudo docker run hello-world
  else
    echo
    echo -e "${WARN}Docker service failed to start.${CLEAR}"
    echo
    exit 1
  fi

}

while getopts 'hir' flag; do
  case "$flag" in
  h)
    usage
    exit 0
    ;;
  i) install ;;
  r) remove ;;
  ?)
    usage
    exit 2
    ;;
  esac
done
