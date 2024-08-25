#!/usr/bin/env bash

# Author: tismatis
# Inspired from tteck installer
# https://github.com/tteck
# https://github.com/tteck/Proxmox/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
 ______ _____  _____    _              _    _ _   _  _____ _    _ ______ _____  
|  ____|  __ \|  __ \  | |        /\  | |  | | \ | |/ ____| |  | |  ____|  __ \ 
| |__  | |__) | |__) | | |       /  \ | |  | |  \| | |    | |__| | |__  | |__) |
|  __| |  _  /|  ___/  | |      / /\ \| |  | | . ` | |    |  __  |  __| |  _  / 
| |    | | \ \| |      | |____ / ____ \ |__| | |\  | |____| |  | | |____| | \ \ 
|_|    |_|  \_\_|      |______/_/    \_\____/|_| \_|\_____|_|  |_|______|_|  \_\
                                                                                 
EOF
}

RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

set -euo pipefail
shopt -s inherit_errexit nullglob

reset_colors() {
  echo -e "${CL}"
}

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

start_routines() {
  header_info

  CHOICE=$(whiptail --backtitle "FRP Launcher" --title "Install or Unistall" --menu "This shell script permit to install and uninstall FRP Launcher, choice what you want to do." 14 58 3 \
    "Install" " " \
    "Uninstall" " " \
    "Reinstall" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  Install)
    install_frplauncher
    ;;
  Uninstall)
    uninstall_frplauncher
    ;;
  Reinstall)
    uninstall_frplauncher
    install_frplauncher
    ;;
  esac
}

install_frplauncher() {

  # FRP Launcher DOWNLOAD & INSTALL
  msg_info "Downloading FRP Launcher"
  mkdir /usr/local/bin/frp-launcher
  wget -q "https://raw.githubusercontent.com/tismatis/frp-launcher/main/frp-launcher.sh" -O "/usr/local/bin/frp-launcher/frp-launcher.sh"
  chmod +x "/usr/local/bin/frp-launcher/frp-launcher.sh"
  msg_ok "Installed FRP Launcher"

  msg_info "Creating default config.toml"
  cat <<EOF >/usr/local/bin/frp-launcher/config.toml
serverAddr = 127.0.0.1
serverPort = 7000
EOF
  msg_ok "Created default config.toml"

  msg_info "Creating default portMappings.csv"
  cat <<EOF >/usr/local/bin/frp-launcher/portMappings.csv
#
# Comments are made starting #
# Port Mapping are made using this format:
# PROTOCOL,TARGETIP,TARGETPORT,REMOTEPORT
# ex:
#   tcp,127.0.0.1,25565,25565
#
EOF
  msg_ok "Created default portMappings.csv"

  # FRP DOWNLOAD & INSTALL
  latest_version=$(get_latest_frp_version)
  version=$(whiptail --backtitle "FRP Launcher" --title "Select FRP version" --inputbox "Enter the FRP version to install (default: $latest_version, recommended: 0.60.0):" 8 58 "$latest_version" 3>&1 1>&2 2>&3)
  local frp_archive="frp_${version}_linux_${arch}.tar.gz"
  local frp_url="https://github.com/fatedier/frp/releases/download/v${version}/${frp_archive}"

  msg_info "Downloading FRP $version for $arch"
  wget -q "$frp_url" -O "/tmp/$frp_archive"
  tar -xzf "/tmp/$frp_archive" -C /usr/local/bin/frp-launcher --strip-components=1
  rm "/tmp/$frp_archive"
  msg_ok "Installed FRP $version for $arch"

  CHOICE=$(whiptail --backtitle "FRP Launcher" --title "Configure config.toml" --menu "We give you the choice to configure directly the default config.toml used by FRP Launcher." 14 58 2 \
    "Yes" " " \
    "No" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  Yes)
    msg_info "Selected to configure config.toml"
    local serverAddress=$(whiptail --backtitle "FRP Launcher" --title "Configure config.toml" --inputbox "Enter the IP Address of the server:" 8 58 "127.0.0.1" 3>&1 1>&2 2>&3)
    local serverPort=$(whiptail --backtitle "FRP Launcher" --title "Configure config.toml" --inputbox "Enter the Port of the server:" 8 58 "7000" 3>&1 1>&2 2>&3)
    msg_info "Saving config.toml"
    cat <<EOF >/usr/local/bin/frp-launcher/config.toml
serverAddr = $serverAddress
serverPort = $serverPort
EOF
    msg_ok "Saved config.toml"
    msg_info "You can still modify config.toml configuration at this path: /usr/local/bin/frp-launcher/config.toml"
    ;;
  No)
    msg_error "Selected no to configure config.toml"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "FRP Launcher" --title "Configure portMappings.csv" --menu "We give you the choice to configure directly (using nano) the default portMappings.csv used by FRP Launcher." 14 58 2 \
    "Yes" " " \
    "No" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  Yes)
    msg_info "Selected to configure portMappings.csv"
    msg_info "Editing portMappings.csv"
    nano /usr/local/bin/frp-launcher/portMappings.csv
    msg_info "You can still modify portMappings.csv configuration at this path: /usr/local/bin/frp-launcher/portMappings.csv"
    ;;
  No)
    msg_error "Selected no to configure portMappings.csv"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "FRP Launcher" --title "Create service" --menu "The setup can create a service for auto start FRP Launcher at the start of your system. Do you want we create a service?" 14 58 2 \
    "Yes" " " \
    "No" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  Yes)
    msg_info "Selected to create a service. Downloading the template from github..."
    wget -q "https://raw.githubusercontent.com/tismatis/frp-launcher/main/misc/frp-launcher.service" -O "/etc/systemd/system/frp-launcher.service"
    systemctl daemon-reload
    msg_ok "Created the service frp-launcher!"
    ;;
  No)
    msg_error "Selected no to create a service."
    ;;
  esac
}

uninstall_frplauncher() {
  msg_info "Stopping FRP service (if exists)"
  systemctl stop frp-launcher.service 2>/dev/null || true
  systemctl disable frp-launcher.service 2>/dev/null || true
  rm -f /etc/systemd/system/frp-launcher.service
  rm -r /usr/local/bin/frp-launcher/
  msg_ok "FRP uninstalled"
}

get_latest_frp_version() {
  # Fetches the latest version from GitHub
  local latest_version
  latest_version=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  echo "$latest_version"
}

get_architecture() {
  case $(uname -m) in
    x86_64) echo "amd64" ;;
    armv7l) echo "arm_hf" ;;
    aarch64) echo "arm64" ;;
    arm*) echo "arm" ;;
    mips) echo "mips" ;;
    mips64) echo "mips64" ;;
    mips64el) echo "mips64le" ;;
    mipsel) echo "mipsle" ;;
    riscv64) echo "riscv64" ;;
    loongarch64) echo "loong64" ;;
    *) echo "unsupported" ;;
  esac
}

arch=$(get_architecture)

header_info
echo -e "\nThis script will permit to install or uninstall FRP Launcher.\n"
while true; do
  read -p "Start the FRP Launcher Setup Script (y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) clear; exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

if [[ "$arch" == "unsupported" ]]; then
  msg_error "The current architecture of the cpu is not supported by FRP."
  echo -e "Requires a cpu in one of following architecture: x86_64,armv7l,aarch64,arm*,mips,mips64,mip64el,mipsel,riscv64,loongarch64."
  echo -e "Exiting..."
  sleep 2
  exit 1
fi

start_routines