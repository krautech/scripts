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


### disclaimer;
qlen=$(ip -s -d link show can0 | grep -oP 'qlen\s\K\w+')
bitrate=$(ip -s -d link show can0 | grep -oP 'bitrate\s\K\w+')

echo "Queuelength:" $qlen
echo "Bitrate:" $bitrate

if [[ $qlen == "1024" ]]; then
	if [[ $bitrate == "1000000" ]]; then
		echo "Script Complete"
	fi
else
	echo "Script FAILED"
fi
