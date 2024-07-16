#!/bin/bash


### Written by KrauTech (https://github.com/krautech)

### Credit to Esoterical (https://github.com/Esoterical)
### I used inspiration and snippet from his debugging script
### Thanks

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

architecture=""
case $(uname -m) in
    i386)   architecture="386" ;;
    i686)   architecture="386" ;;
    x86_64) architecture="amd64" ;;
    arm)    dpkg --print-architecture | grep -q "arm64" && architecture="arm64" || architecture="arm" ;;
esac
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
