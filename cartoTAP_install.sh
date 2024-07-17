#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;36m'
NC='\033[0m' # No Color
### Written by KrauTech (https://github.com/krautech)

### Credit to Esoterical (https://github.com/Esoterical)
### I used inspiration and snippet from his debugging script
### Thanks
header(){
	clear
printf "${GREEN}
   ____                  _             _____      _      ____      ____    _____   _____      _    
  / ___|   __ _   _ __  | |_    ___   |_   _|    / \    |  _ \    | __ )  | ____| |_   _|    / \   
 | |      / _  | | '__| | __|  / _ \    | |     / _ \   | |_) |   |  _ \  |  _|     | |     / _ \  
 | |___  | (_| | | |    | |_  | (_) |   | |    / ___ \  |  __/    | |_) | | |___    | |    / ___ \ 
  \____|  \__,_| |_|     \__|  \___/    |_|   /_/   \_\ |_|       |____/  |_____|   |_|   /_/   \_\
																								   

${NC}"
printf "${RED}BETA Script ${NC} v0.1.2\n"
printf "Created by ${GREEN}KrauTech${NC} ${BLUE}(https://github.com/krautech)${NC}\n"
}
header;
saved_uuid=""

disclaimer() {
	echo "*************"
	echo "* Attention *"
	echo "*************"
	echo
	echo "This script is designed to update your firmware with the beta firmware."
	echo "As well as install GH, Pull CartoTAP and Update Moonraker.conf"
	echo ""
	printf "${RED}USE AT YOUR OWN RISK${NC}"
	echo ""
	echo "This script is available for review at: "
	printf "${BLUE}https://github.com/krautech/scripts/blob/main/cartoTAP_install.sh${NC}\n\n"
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
sudo service klipper stop
echo ""
echo ""

install_pre(){
	header;
	cd ~
	architecture=""
	case $(uname -m) in
		i386)   architecture="386" ;;
		i686)   architecture="386" ;;
		x86_64) architecture="amd64" ;;
		arm)    dpkg --print-architecture | grep -q "arm64" && architecture="arm64" || architecture="arm" ;;
	esac

	check=$(command -v gh)
	if ! [[ $check == "/usr/bin/gh" ]]; then
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


}

check_uuid(){
	header;
	echo "###################################################################################"
	echo "Please enter your cartographer UUID"
	echo "found usually in your printer.cfg under [cartographer] or [scanner]"
	echo 
	echo "To go back: b"
	echo
	echo -n "UUID: "
	read -r uuid
	
	if ! [[ $uuid == "b" ]]; then
		checkuuid=$(python3 ~/katapult/scripts/flashtool.py -i can0 -u $uuid -r | grep -s "Flash Success")
		if [[ $checkuuid == "Flash Success" ]]; then
			echo "UUID Check: Success"
			##echo "DEBUG CHECK UUID:"$checkuuid
		else
			echo "UUID Check Failed: ${checkuuid}"
		fi
	fi
}



check_katapult(){
	header;
	echo "###################################################################################"
	echo "Checking device is in Katapult Mode"
	~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0
	check_it=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep "CanBoot")
		if [[ $check_it != "" ]]; then
			saved_uuid=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -oP "canbus_uuid=\K.*" | sed -e 's/, Application: CanBoot//g')
		else
			check_it2=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep "Katapult")
			if [[ $check_it2 != "" ]]; then
				saved_uuid=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -oP "canbus_uuid=\K.*" | sed -e 's/, Application: Katapult//g')
			else
				echo "Something is Wrong - No Device in Katapult Mode"
			fi
		fi
	klippercheck=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -oP "canbus_uuid=${saved_uuid}, Application: Klipper")
	if [[ $saved_uuid != "" ]] && [[ $klippercheck == "" ]]; then
		##echo "DEBUG 1: "$saved_uuid
		##echo "DEBUG 2: "$klippercheck
		check_flash;
	fi
}

check_dfu(){
	header;
	echo "###################################################################################"
	echo "Checking device is in DFU Mode"
	lsusb
	echo 
	echo
	dfucheck=$(lsusb | grep -oP "DFU Mode")
	if [[ $dfucheck == "DFU Mode" ]]; then
		deviceid=$(lsusb | grep "DFU Mode" | awk '{print $6}');
		echo "Your Cartographer Device ID: "$deviceid
		echo 
		printf "${GREEN}YOUR DEVICE IS IN DFU MODE${NC}"
		echo 
	fi
}

check_usb(){
	header;
	echo "###################################################################################"
	echo "Checking USB Device Serial ID"
	lsusb
	echo 
	echo
	usbcheck=$(ls -l /dev/serial/by-id/ | grep -oP "Cartographer")
	if [[ $usbcheck == "Cartographer" ]]; then
		usbid=$(ls -l /dev/serial/by-id/ | grep "Cartographer" | awk '{print $9}');
		printf "Your Cartographer Device Serial ID: ${GREEN}${usbid}${NC}"
		echo 
	fi
}

500k(){
	echo "###################################################################################"
	options=("Yes Continue" "No")
	echo "Baudrate: 500k"
	echo "Do you wish to proceed with flashing your cartographer probe?"
	select opt in "${options[@]}"; do
		case $REPLY in
			1) python3 ~/katapult/scripts/flash_can.py -i can0 -f 500k.bin -u $saved_uuid; break ;;
			2) break 2 ;;
			*) echo "What's that?" >&2
		esac
	done
}
1m(){
	echo "###################################################################################"
	options=("Yes Continue" "No")
	echo "Baudrate: 1M"
	echo "Do you wish to proceed with flashing your cartographer probe?"
	select opt in "${options[@]}"; do
		case $REPLY in
			1) python3 ~/katapult/scripts/flash_can.py -i can0 -f 1m.bin -u $saved_uuid; break ;;
			2) break 2 ;;
			*) echo "What's that?" >&2
		esac
	done
}


probe(){
	header;
	echo "###################################################################################"
	if [ -d ~/Carto_TAP/FW/V3 ]; then
		cd ~/Carto_TAP/FW/V3
	elif [ -d ~/Carto_TAP/FW/V2 ]; then
		cd ~/Carto_TAP/FW/V2
	elif [ -d ~/Carto_TAP/FW/V2-V3 ]; then
		cd ~/Carto_TAP/FW/V2-V3
	else
		echo "You are missing Prerequisites. Please install them first."
		break;
	fi
	bitrate=$(ip -s -d link show can0 | grep -oP 'bitrate\s\K\w+')
	while true; do
		options=("500k" "1M" "I Dont know")
		printf "According to your HOST machine, your CanBus Bitrate is: ${RED}${bitrate}${NC}"
		echo 
		echo 
		echo "What is your CanBUS bitrate?"
		select opt in "${options[@]}"; do
			case $REPLY in
				1) 500k; break ;;
				2) 1m; break ;;
				3) break 2 ;;
				*) echo "What's that?" >&2
			esac
		done
		
		echo "Are we done flashing your probe?"
		select opt in "Yes" "No"; do
			case $REPLY in
				1) break 2 ;;
				2) break ;;
				*) echo "Look, it's a simple question..." >&2
			esac
		done
	done
}

probe_dfu(){
	header;
	echo "###################################################################################"
	if [ -d ~/Carto_TAP/FW/V3 ]; then
		cd ~/Carto_TAP/FW/V3
	elif [ -d ~/Carto_TAP/FW/V2 ]; then
		cd ~/Carto_TAP/FW/V2
	elif [ -d ~/Carto_TAP/FW/V2-V3 ]; then
		cd ~/Carto_TAP/FW/V2-V3
	else
		echo "You are missing Prerequisites. Please install them first."
		break ;
	fi
	
	wget https://apdm.tech/katapult_and_carto_can_1m_beta.bin
	options=("Yes Continue" "No")
	echo "Firmware File: katapult_and_carto_can_1m_beta.bin"
	echo "Do you wish to proceed with flashing your cartographer probe using DFU Mode?"
	select opt in "${options[@]}"; do
		case $REPLY in
			1) dfu-util -R -a 0 -s 0x08002000:leave -D katapult_and_carto_can_1m_beta.bin; break ;;
			2) break 2 ;;
			*) echo "What's that?" >&2
		esac
	done
}

probe_usb(){
	header;
	echo "###################################################################################"
	options=("Yes Continue" "No")
	echo "Firmware File: usb.bin"
	echo "Do you wish to proceed with flashing your cartographer probe using USB Mode?"
	select opt in "${options[@]}"; do
		case $REPLY in
			1) 	cd ~/klipper/scripts
				~/klippy-env/bin/python -c 'import flash_usb as u; u.enter_bootloader("/dev/serial/by-id/${usbid}")'
				katapultid=$(ls -l /dev/serial/by-id/ | grep "katapult" | awk '{print $9}');
				if [ -d ~/Carto_TAP/FW/V3 ]; then
					cd ~/Carto_TAP/FW/V3
				elif [ -d ~/Carto_TAP/FW/V2 ]; then
					cd ~/Carto_TAP/FW/V2
				elif [ -d ~/Carto_TAP/FW/V2-V3 ]; then
					cd ~/Carto_TAP/FW/V2-V3
				else
					echo "You are missing Prerequisites. Please install them first."
					break ;
				fi
				~/klippy-env/bin/python ~/klipper/lib/canboot/flash_can.py -f usb.bin -d /dev/serial/by-id/$katapultid
				break ;;
			2) break 2 ;;
			*) echo "What's that?" >&2
		esac
	done
}

check_flash(){
	echo "Do you want to flash your probe?"
	options=("Yes" "No")
		select opt in "${options[@]}"; do
			case $REPLY in
				1) probe; break ;;
				2) break ;;
				*) echo "What's that?" >&2
			esac
		done

}

while true; do
	echo "###################################################################################"
	echo ""
	printf "${RED}FIRMWARE FLASH${NC} is available once you finish checking your UUID & Katapult Mode."
	echo ""
	echo ""
    echo "Choose an option:"
	if [[ $saved_uuid == "" ]] && [[ $deviceid == "" ]] && [[ $usbid == "" ]]; then
		options=("Install Prerequisites (GH, CartoTAP Repo, Config Moonraker)" "Check UUID & Enter Katapult" "Check Katapult Mode" "Check DFU Mode" "Check USB Serial" "Quit")
		select opt in "${options[@]}"; do
			case $REPLY in
				1) install_pre; break ;;
				2) check_uuid; break ;;
				3) check_katapult; break ;;
				4) check_dfu; break ;;
				5) check_usb; break ;;
				6) exit; break ;;
				*) echo "What's that?" >&2
			esac
		done
	elif [[ $deviceid != "" ]]; then
		options=("Install Prerequisites (GH, CartoTAP Repo, Config Moonraker)" "Check DFU Mode" "Flash Cartographer CANBUS ONLY - via DFU" "Quit")
		select opt in "${options[@]}"; do
			case $REPLY in
				1) install_pre; break ;;
				2) check_dfu; break ;;
				3) probe_dfu; break ;;
				4) exit; break ;;
				*) echo "What's that?" >&2
			esac
		done
	elif [[ $saved_uuid != "" ]]; then
		options=("Install Prerequisites (GH, CartoTAP Repo, Config Moonraker)" "Check UUID & Enter Katapult" "Check Katapult Mode" "Flash Cartographer CANBUS ONLY - via Katapult" "Quit")
		select opt in "${options[@]}"; do
			case $REPLY in
				1) install_pre; break ;;
				2) check_uuid; break ;;
				3) check_katapult; break ;;
				4) probe; break ;;
				5) exit; break ;;
				*) echo "What's that?" >&2
			esac
		done
	elif [[ $usbid != "" ]]; then
		options=("Install Prerequisites (GH, CartoTAP Repo, Config Moonraker)" "Check USB Serial" "Flash Cartographer USB" "Quit")
		select opt in "${options[@]}"; do
			case $REPLY in
				1) install_pre; break ;;
				2) check_usb; break ;;
				3) probe_usb; break ;;
				4) exit; break ;;
				*) echo "What's that?" >&2
			esac
		done
	fi

done


cd ~



