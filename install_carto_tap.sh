#!/bin/bash


### Written by KrauTech (https://github.com/krautech)

### Credit to Esoterical (https://github.com/Esoterical)
### I used inspiration and snippet from his debugging script
### Thanks
echo " 


   ____                  _             _____      _      ____      ____    _____   _____      _    
  / ___|   __ _   _ __  | |_    ___   |_   _|    / \    |  _ \    | __ )  | ____| |_   _|    / \   
 | |      / _  | | '__| | __|  / _ \    | |     / _ \   | |_) |   |  _ \  |  _|     | |     / _ \  
 | |___  | (_| | | |    | |_  | (_) |   | |    / ___ \  |  __/    | |_) | | |___    | |    / ___ \ 
  \____|  \__,_| |_|     \__|  \___/    |_|   /_/   \_\ |_|       |____/  |_____|   |_|   /_/   \_\
                                                                                                   


"
disclaimer() {
	echo "*************"
	echo "* Attention *"
	echo "*************"
	echo
	echo "This script is designed to automatically install GitHub CLI"
	echo "This script is available for review at: "
	echo "https://github.com/krautech/scripts/blob/main/installgh.sh"
	echo

	while true; do
		read -p "Do you wish to run this program? (yes/no) " yn < /dev/tty
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}


disclaimer;
cd ~
architecture=""
case $(uname -m) in
    i386)   architecture="386" ;;
    i686)   architecture="386" ;;
    x86_64) architecture="amd64" ;;
    arm)    dpkg --print-architecture | grep -q "arm64" && architecture="arm64" || architecture="arm" ;;
esac

check=$(command -v gh auth login)
if ! grep -q "/usr/bin/gh" $check;
then
	if [[ $architecture == "" ]]; then
		arch=$(uname -m | sed 's/^aarch64$/arm64/')

		if [[ $arch == "arm64" ]]; then
			wget https://github.com/cli/cli/releases/download/v2.51.0/gh_2.51.0_linux_arm64.deb
			sudo dpkg -i gh_2.51.0_linux_arm64.deb
		else
			wget https://github.com/cli/cli/releases/download/v2.51.0/gh_2.51.0_linux_armv6.deb
			sudo dpkg -i gh_2.51.0_linux_armv6.deb
		fi
	else
		wget https://github.com/cli/cli/releases/download/v2.51.0/gh_2.51.0_linux_armv6.deb
		sudo dpkg -i gh_2.51.0_linux_armv6.deb
	fi
fi

if grep -q "github.com" .config/gh/hosts.yml; then
	cd ~
	git clone https://github.com/Cartographer3D/Carto_TAP.git
	./Carto_TAP/install.sh
else
	echo $(gh auth login)
	cd ~
	git clone https://github.com/Cartographer3D/Carto_TAP.git
	./Carto_TAP/install.sh
fi

cd ~
cd printer_data/config
if ! grep -q "CartographerSurveyBeta" moonraker.conf; then
	echo "
[update_manager CartographerSurveyBeta]
type: git_repo
path: ~/Carto_TAP
origin: https://github.com/Cartographer3D/Carto_TAP.git
env: ~/klippy-env/bin/python
install_script: install.sh
is_system_service: False
managed_services: klipper
requirements: requirements.txt 
info_tags:
  desc=Cartographer Survey - BETA" >> moonraker.conf
else
	echo "Moonraker is already configured for Cartographer Survey - BETA"
fi

read -p 'Press Enter to Complete Setup and Reboot '
sleep 10
sudo shutdown -r now