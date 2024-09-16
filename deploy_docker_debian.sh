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

ubuntu_codenames=(
  "focal"
  "jammy"
  "noble"
)

is_ubuntu_installation=false

debian_codenames=(
  "bookworm"
  "bullseye"
)

is_debian_installation=false

check_codenames() {
  codenames=(${ubuntu_codenames[@]} ${debian_codenames[@]})

  # Check for lsb_release
  if [[ -x /usr/bin/lsb_release ]]; then

    supported_os=false

    # Loop through the above defined codenames and
    # if the OS codename matches, continue with script.
    for codename in "${codenames[@]}"; do
      if [[ $codename == $(lsb_release -sc) ]]; then
        supported_os=true
        if [[ $codename == "bookworm" || $codename == "bullseye" ]]; then
          is_debian_installation=true
        else
          is_ubuntu_installation=true
        fi
        break
      else
        supported_os=false
      fi
    done

    # If we don't have a supported OS, exit.
    if [[ ! $supported_os == 1 ]]; then
      echo
      echo -e "${WARN}Unsupported OS. Only supports ${codenames[@]}"
      echo
      exit 2
    fi

  else
    # Exit the script right away if we don't have lsb_release available.
    echo
    echo -e "${WARN}lsb_release is not found.. Exiting.."
    echo
    exit 2
  fi
}

# Echo the usage string
usage() {
  echo
  echo -e $usage_string
  echo
}

remove() {
  # Start the removal process by checking that this OS is supported.
  check_codenames

  echo
  echo -e "${INFO}Removing docker binaries, gpg key, and apt list."
  echo
  # Uninstall docker engine binaries
  for pkg in "${docker_packages[@]}"; do
    sudo apt remove $pkg -y
  done

  # If the apt list exists, remove it.
  if [ -e /etc/apt/sources.list.d/docker.list ]; then
    sudo rm -v /etc/apt/sources.list.d/docker.list
  else
    echo
    echo -e "${INFO}Docker apt list not found.. skipping"
    echo
  fi

  # If the GPG key exists, remove it.
  if [ -e /etc/apt/keyrings/docker.asc ]; then
    sudo rm -v /etc/apt/keyrings/docker.asc
  else
    echo
    echo -e "${INFO}Docker gpg key not found.. skipping"
    echo
  fi

  echo
  echo -e "${INFO}Successfully cleaned up."
  echo
  exit 0
}

install() {
  # Start the installation with a check if the OS is supported
  check_codenames

  echo
  echo -e "${INFO}Updating and installing ca-certificates and curl"
  echo

  # Install ca-certificates and curl
  sudo apt update
  sudo apt install ca-certificates curl -y

  echo
  echo -e "${INFO}Setting up Docker GPG key"
  echo

  # Set up the keyrings directory with permissions
  sudo install -m 0755 -d /etc/apt/keyrings

  # Check to make sure the GPG doesn't exist and install it.
  if [[ ! -e /etc/apt/keyrings/docker.asc ]]; then
    if [[ $is_ubuntu_installation == true ]]; then
      sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc]\
        https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    elif [[ $is_debian_installation == true ]]; then
      sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc

      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc]\
        https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    else
      echo -e "${WARN}NO DETECTED OS INSTALLATION"
      exit 99
    fi

    sudo chmod a+r /etc/apt/keyrings/docker.asc
  else
    echo -e "${WARN}Docker gpg key not found.. Exiting"
    exit 1
  fi

  echo
  echo -e "${INFO}Updating repositories and installing docker binaries.."
  echo

  # Install the docker binaries
  sudo apt update
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

  # If the docker binary exists, we have successfully installed docker engine.
  # Run the hello-world container to verify correct installation.
  if [[ -x /usr/bin/docker ]]; then
    echo
    echo -e "${SUCCESS}Docker successfully installed. Running hello-world.."
    echo

    sudo docker run hello-world

    exit 0
  else
    echo
    echo -e "${WARN}Docker not installed correctly."
    echo
    exit 1
  fi
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
