#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;36m'
NC='\033[0m' # No Color
### Written by KrauTech (https://github.com/krautech)

### Credit to Esoterical (https://github.com/Esoterical)
### I used inspiration and snippet from his debugging script
### Thanks
sudo service klipper stop


##
# Color  Variables
##
red='\r\033[31m'
green='\r\033[32m'
blue='\r\033[1;36m'
yellow='\r\033[1;33m'
clear='\e[0m'

##
# Color Functions
##
ColorRed(){
	echo -ne $red$1$clear
}
ColorGreen(){
	echo -ne $green$1$clear
}
ColorBlue(){
	echo -ne $blue$1$clear
}
ColorYellow(){
	echo -ne $yellow$1$clear
}
header(){
clear
printf "${GREEN}


   ____                  _                                            _                   
  / ___|   __ _   _ __  | |_    ___     __ _   _ __    __ _   _ __   | |__     ___   _ __ 
 | |      / _  | | '__| | __|  / _ \   / _  | | '__|  / _  | | '_ \  | '_ \   / _ \ | '__|
 | |___  | (_| | | |    | |_  | (_) | | (_| | | |    | (_| | | |_) | | | | | |  __/ | |   
  \____|  \__,_| |_|     \__|  \___/   \__, | |_|     \__,_| | .__/  |_| |_|  \___| |_|   
                                       |___/                 |_|                          

${NC}"
printf "${RED}Firmware Flasher Script ${NC} v0.1.6a\n"
printf "Created by ${GREEN}KrauTech${NC} ${BLUE}(https://github.com/krautech)${NC}\n"
echo
echo
printf "${RED}###################################################################################${NC}\n"
}
header;
saved_uuid=""

disclaimer() {
	# Show Disclaimer FUNCTION
	echo "******************************************************************"
	echo "* Attention *"
	echo "******************************************************************"
	echo
	echo "This script is designed to update your firmware via Katapult/DFU/USB"
	echo ""
	printf "${RED}USE AT YOUR OWN RISK${NC}"
	echo ""
	echo "This script is available for review at: "
	printf "${BLUE}https://github.com/krautech/scripts/blob/main/CartoFirmware_Flasher.sh${NC}\n\n"
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

instructions() {
	# Show Instructions FUNCTION
	echo "******************************************************************"	
	printf "${GREEN}Flashing via Katapult - Canbus${NC}\n"
	echo "******************************************************************"	
	echo "Step 1: Plug Cartographer into Canbus cable to host/toolhead."
	echo "Step 2: Press 2 to install pre-requisites."
	echo "Step 3: Canbus should be detected, if not, enter your cartographer UUID."
	echo "Step 4: Press 6 to flash classic firmware (1M or 500k bitrate, auto selected) to Cartographer."
	echo "Step 3: Cycle printer power."
	echo "******************************************************************"	
	printf "${GREEN}Flashing via Katapult - USB${NC}\n"
	echo "******************************************************************"	
	echo "Step 1: Plug Cartographer into USB to host/toolhead."
	echo "Step 2: Press 2 to install pre-requisites."
	echo "Step 3: Cartographer should be detected. If not, Press 3 to check."
	echo "Step 4: Press 6 to flash USB firmware to Cartographer."
	echo "Step 3: Cycle printer power."
	echo "******************************************************************"
	printf "${GREEN}Flashing via DFU${NC}\n"
	echo "******************************************************************"
	echo "Step 1: Plug Cartographer in via USB to host."
	echo "Step 2: Tap 'Boot0' on your cartographer to enter DFU."
	echo " - Sometimes holding 'Boot0' and tapping 'reset' is required"
	printf " - Type ${RED}lsusb${NC} until your device shows in DFU mode.\n"
	echo "Step 3: Press 2 to install pre-requisites."
	echo "Step 4: Press 4 to check for flashable devices."
	echo "Step 5: Press 6 to flash firmware via DFU."
	echo "Step 6: Cycle printer power"
	echo 
	echo 
	read -p "Press enter to return to main menu"
}


menu(){
	# Show the Main Menu FUNCTION
	header;
	if [[ $findUUID != "" ]]; then
		echo -ne "$(ColorBlue 'Cartographer Canbus UUID detected: ')"
		echo $findUUID
		echo 
	fi
	if [[ $canbootID != "" ]] || [[ $katapultID != "" ]]; then
		echo -ne "$(ColorGreen 'Canbus Katapult Device Found for Flashing')\n"
	fi
	if [[ $dfuID != "" ]]; then
		echo -ne "$(ColorGreen 'DFU Device Found for Flashing')\n"
	fi
	if [[ $usbID != "" ]]; then
		echo -ne "$(ColorGreen 'USB Katapult Device Found for Flashing')\n"
	fi
	if [[ $canbootID == "" ]] && [[ $katapultID == "" ]] && [[ $dfuID == "" ]] && [[ $usbID == "" ]]; then
		echo -ne "$(ColorRed 'No Device Found in Flashing Mode')\n"
	fi
	echo -ne "
					$(ColorYellow '1)') Instructions"
	if [ ! -d ~/katapult ] && [ ! -d ~/Carto_TAP ] && ! grep -q "CartographerSurveyBeta" ~/printer_data/config/moonraker.conf; then
	echo -ne "
			$(ColorYellow '2)') Install Prerequisites\n"
	else
		if [[ $found == "" ]]; then
			echo -ne "
					$(ColorGreen '3)') Run lsusb"
		fi
		if [[ $found == "" ]]; then
			echo -ne "
					$(ColorGreen '4)') Check For Flashable Devices"
		fi
		
		if [[ $checkuuid == "" ]] && [[ $usbID == "" ]] && [[ $dfuID == "" ]]; then
		echo -ne "
				$(ColorGreen '5)') Check Canbus UUID And Or Enter Canbus Katapult Mode\n"
		fi
		if [[ $canbootID != "" ]] || [[ $katapultID != "" ]] || [[ $dfuID != "" ]] || [[ $usbID != "" ]]; then
			echo -ne "
				$(ColorBlue '6)') Flash Firmware"
		fi
	fi
	echo -ne "\n	
		$(ColorRed 'r)') Reboot
		$(ColorRed 'q)') Exit without Rebooting\n"
	echo -ne "\n	
		$(ColorBlue 'Choose an option:') "
    read a
	COLUMNS=12
    case $a in
		1) instructions ; menu ;;
	    2) installPre ; menu ;;
		3) 
		lsusb
		read -p "Press enter to return to main menu"; menu ;;
	    4) initialChecks ; menu ;;
	    5) checkUUID ; menu ;;
		6) flashFirmware ; menu ;;
		"lsusb") 
		lsusb
		read -p "Press enter to return to main menu"; menu ;;
		"q") sudo service klipper start; exit;;
		"r") sudo reboot; exit;;
		*) echo -e $red"Wrong option."$clear;;
    esac
}

initialChecks(){
	# Begin Checking For Devices FUNCTION
	header;
	echo "Running Checks for Cartographer Devices in Katapult Mode (Canbus & USB) or DFU"
	echo 
	if [ -d ~/katapult ]; then
		cd ~/katapult
		git pull > /dev/null 2>&1
		canCheck=$(ip -s -d link | grep "can0")
		if [[ $canCheck != "" ]]; then
			findUUID=$(grep -E "\[scanner\]" ~/printer_data/logs/klippy.log -A 3 | grep uuid | tail -1 | awk '{print $3}')
			if [[ $findUUID == "" ]]; then
				findUUID=$(grep -E "\[cartographer\]" ~/printer_data/logs/klippy.log -A 3| grep uuid | tail -1 | awk '{print $3}')
				if [[ $findUUID != "" ]]; then
					checkuuid=$(python3 ~/katapult/scripts/flashtool.py -i can0 -u $findUUID -r | grep -s "Flash Success")
					fi 
			else
				checkuuid=$(python3 ~/katapult/scripts/flashtool.py -i can0 -u $findUUID -r | grep -s "Flash Success")
			fi
			# Check for canboot device
			canbootCheck=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep  -m 1 "CanBoot")
			if [[ $canbootCheck != "" ]]; then
				# Save CanBoot Device UUID
				canbootID=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -m 1 -oP "canbus_uuid=\K.*" | sed -e 's/, Application: CanBoot//g')
				klippercheck=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep  -m 1 -oP "canbus_uuid=${canbootID}, Application: Klipper")
				found=1
			fi	
			# Check for Canbus Katapult device
			katapultCheck=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep  -m 1 "Katapult")
			if [[ $katapultCheck != "" ]]; then
				# Save Katapult Device UUID
				katapultID=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -m 1 -oP "canbus_uuid=\K.*" | sed -e 's/, Application: Katapult//g')
				klippercheck=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep  -m 1 -oP "canbus_uuid=${katapultID}, Application: Klipper")
				found=1
			fi
		fi
	fi
	# Check for Device in DFU Mode Instead
	dfuCheck=$(lsusb | grep -oP "DFU Mode")
	if [[ $dfuCheck == "DFU Mode" ]]; then
		# Save DFU Device ID
		dfuID=$(lsusb | grep "DFU Mode" | awk '{print $6}');
		found=1
		#echo "DFU Flash is Disabled"
	fi
	# Check For Katapult USB Serials
	if [ -d /dev/serial/by-id/ ]; then
		# Check for Cartographer USB
		usbCheck=$(ls -l /dev/serial/by-id/ | grep -oP "Cartographer")
			if [[ $usbCheck == "Cartographer" ]]; then
				# Save USB ID
				usbID=$(ls -l /dev/serial/by-id/ | grep "Cartographer" | awk '{print $9}');
				found=1
			fi
	fi

}

installPre(){
	# Installs all needed files FUNCTION
	header;
	echo "Installing all necessary components.."
	echo 
	cd ~
	# Check for Katapult installation
	if [ ! -d ~/katapult ]; then
		# Pull & Install Katapult
		test -e ~/katapult && (cd ~/katapult && git pull) || (cd ~ && git clone https://github.com/Arksine/katapult) ; cd ~
		if [ -d ~/katapult ]; then
			printf "${GREEN}Katapult was SUCCESSFULLY installed.${NC}\n\n"
		else
			printf "${RED}Katapult FAILED to install$.{NC}\n\n"
		fi
	else 
		echo "Katapult is already installed"
		echo
	fi
	# Check for Cartographer-Klipper installation
	if [ ! -d ~/cartographer-klipper ]; then
		# Pull Cartographer-Klipper
		test -e ~/cartographer-klipper && (cd ~/cartographer-klipper && git pull) || (cd ~ && git clone https://github.com/Cartographer3D/cartographer-klipper.git) ; cd ~
		if [ -d ~/cartographer-klipper ]; then
			# Install Cartographer-Klipper
			chmod +x cartographer-klipper/install.sh
			./cartographer-klipper/install.sh
			printf "${GREEN}Cartographer-Klipper was SUCCESSFULLY installed.${NC}\n\n"
		else
			printf "${RED}Cartographer-Klipper FAILED to install$.{NC}\n\n"
		fi
	else 
		echo "Cartographer-Klipper is already installed"
		echo
	fi
		
	read -p "Press enter to continue"
}
checkUUID(){
	if [[ $checkuuid == "" ]]; then
		# Checks Users UUID and Put Device into Katapult Mode
		header;
		echo "This is only needed if youre using CANBUS"
		echo 
		echo "Please enter your cartographer canbus UUID"
		echo "found usually in your printer.cfg under [cartographer] or [scanner]"
		echo 
		echo "To go back: b"
		echo
		echo -n "UUID: "
		read -p "" -i $findUUID -e uuid		
		# If user entered a valid UUID
		if ! [[ $uuid == "b" ]]; then
			cd ~/katapult
			git pull > /dev/null 2>&1
			# Check If UUID is valid and puts device into Katapult Mode
			checkuuid=$(python3 ~/katapult/scripts/flashtool.py -i can0 -u $uuid -r | grep -s "Flash Success")
			if [[ $checkuuid == "Flash Success" ]]; then
				printf "UUID Check: ${GREEN}Success & Entered Katapult Mode${NC}\n"
				read -p "Press enter to check for flashable device"
				initialChecks;
				##echo "DEBUG CHECK UUID:"$checkuuid
			else
				echo "UUID Check Failed: ${checkuuid}"
				read -p "Press enter to go back"
			fi
		fi
	fi
}

flashFirmware(){
	# List Firmware for Found Device FUNCTION
	header;
	echo "Pick which firmware you want to install, if unsure ask on discord (https://discord.gg/yzazQMEGS2)"
	echo
	# If found device is Katapult
	if [[ $canbootID != "" ]] || [[ $katapultID != "" ]]; then
		bitrate=$(ip -s -d link show can0 | grep -oP 'bitrate\s\K\w+')
		printf "Your Host CANBus is configured at ${RED}Bitrate: $bitrate"
		echo 
		printf "${BLUE}Flashing via ${GREEN}CANBUS - KATAPULT${NC}\n\n"
		cd ~/cartographer-klipper
		git pull > /dev/null 2>&1
		cd ~/cartographer-klipper/firmware/v3
		DIRECTORY=.
		unset options i
		while IFS= read -r -d $'\0' f; do
		  options[i++]="$f"
		done < <(find $DIRECTORY -maxdepth 1 -type f -name "*Cartographer_*" -print0 )
		COLUMNS=12
		select opt in "${options[@]}" "Back"; do
			case $opt in
				*Cartographer_*)
					flashing $opt;
					;;
				"Back")
					menu ; break
					;;
				*)
					echo "This is not a number"
				;;
			esac
		done
	fi
	# If found device is DFU
	if [[ $dfuID != "" ]]; then
		printf "${BLUE}Flashing via ${GREEN}DFU${NC}\n\n"
		cd ~/cartographer-klipper
		git pull > /dev/null 2>&1
		cd ~/cartographer-klipper/firmware/v3/'DEPLOYER FRIMWARE - DFU MODE ONLY NOT KATAPULT'
		DIRECTORY=.
		unset options i
		while IFS= read -r -d $'\0' f; do
		  options[i++]="$f"
		done < <(find $DIRECTORY -maxdepth 1 -type f -name "*Cartographer_*" -print0 )
		COLUMNS=12
		select opt in "${options[@]}" "Back"; do
			case $opt in
				*Cartographer_*)
					flashing $opt;
					;;
				"Back")
					menu ; break
					;;
				*)
					echo "This is not a number"
				;;
			esac
		done
	fi
	# If found device is USB
	if [[ $usbID != "" ]]; then
		printf "${BLUE}Flashing via ${GREEN}USB - KATAPULT${NC}\n\n"
		cd ~/cartographer-klipper
		git pull > /dev/null 2>&1
		cd ~/cartographer-klipper/firmware/v3
		DIRECTORY=.
		unset options i
		while IFS= read -r -d $'\0' f; do
		  options[i++]="$f"
		done < <(find $DIRECTORY -maxdepth 1 -type f -name "*Cartographer_*" -print0 )
		COLUMNS=12
		select opt in "${options[@]}" "Back"; do
			case $opt in
				*Cartographer_*)
					flashing $opt;
					;;
				"Back")
					menu ; break
					;;
				*)
					echo "This is not a number"
				;;
			esac
		done

		
	fi
	read -p "Press enter to continue"
}

flashing(){
	# Flash Device FUNCTION
	header;
	cd ~/cartographer-klipper/firmware/v3
	firmwareFile=$(echo "$1" | sed 's|./||g')
	if [[ $canbootID != "" ]]; then
		uuid=$canbootID
	fi
	if [[ $katapultID != "" ]]; then
		uuid=$katapultID
	fi
	if [[ $firmwareFile != "" ]]; then
		echo "Flashing Device $uuid $dfuID $usbID"
		echo "Flashing with $firmwareFile ..."
	
		# Check if Katapult
		if [[ $canbootID != "" ]] || [[ $katapultID != "" ]]; then
			# Flash Katapult Firmware
			python3 ~/katapult/scripts/flash_can.py -i can0 -f $firmwareFile -u $uuid;
			canbootID=""
			katapultID=""
			echo
		fi
		
		# Check if DFU
		if [[ $dfuID != "" ]]; then
			# Flash DFU Firmware
			cd ~/cartographer-klipper/firmware/v3/'DEPLOYER FRIMWARE - DFU MODE ONLY NOT KATAPULT'
			sudo dfu-util --device ,$dfuID -R -a 0 -s 0x08000000:leave -D $firmwareFile
			dfuID=""
			echo
		fi
		
		# Check if USB
		if [[ $usbID != "" ]]; then
			# FLash USB Firmware
			cd ~/klipper/scripts
			~/klippy-env/bin/python -c 'import flash_usb as u; u.enter_bootloader("/dev/serial/by-id/${usbID}")'
			flashID=$(ls -l /dev/serial/by-id/ | grep "katapult" | awk '{print $9}');
			if [ -d ~/cartographer-klipper/firmware/v3 ]; then
				cd ~/cartographer-klipper/firmware/v3
			else
				echo "You are missing firmware files. Please pull them from github first."
				break ;
			fi
			~/klippy-env/bin/python ~/klipper/lib/canboot/flash_can.py -f $firmwareFile -d /dev/serial/by-id/$flashID
			usbID=""
		fi
		flashed="1"
		read -p "Press enter to continue"
		menu;
	else
		echo "Firmware file not found to be flashed"
		flashed="0"
		read -p "Press enter to continue"
		menu;
	fi
}

disclaimer;

initialChecks;

menu;





