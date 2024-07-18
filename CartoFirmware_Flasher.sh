#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;36m'
NC='\033[0m' # No Color
### Written by KrauTech (https://github.com/krautech)

### Credit to Esoterical (https://github.com/Esoterical)
### I used inspiration and snippet from his debugging script
### Thanks
#sudo service klipper stop


##
# Color  Variables
##
red='\e\r[31m'
green='\e\r[32m'
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
printf "${RED}Firmware Flasher Script ${NC} v0.1.2\n"
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

menu(){
	# Show the Main Menu FUNCTION
	header;
	if [[ $canbootID != "" ]] || [[ $katapultID != "" ]]; then
		echo -ne "$(ColorGreen 'Katapult Device Found for Flashing')\n"
	fi
	if [[ $dfuID != "" ]]; then
		echo -ne "$(ColorGreen 'DFU Device Found for Flashing')\n"
	fi
	if [[ $usbID != "" ]]; then
		echo -ne "$(ColorGreen 'USB Device Found for Flashing')\n"
	fi
	echo -ne "
			$(ColorYellow '1)') Install Prerequisites\n
			$(ColorGreen '2)') Check For Flashable Devices
			$(ColorGreen '3)') Check UUID & Enter Katapult Mode\n"
	
	if [[ $canbootID != "" ]] || [[ $katapultID != "" ]] || [[ $dfuID != "" ]] || [[ $usbID != "" ]]; then
		echo -ne "
			$(ColorBlue '4)') Flash Firmware "
	fi
	if [[ $flashed == "1" ]]; then
		echo -ne "\n
			$(ColorRed 'R)') Reboot & Exit"
		echo -ne "\n
			$(ColorRed 'Q)') Exit without Rebooting"
	else
		echo -ne "\n
			$(ColorRed 'Q)') Exit"
	fi
	echo -ne "\n	
		$(ColorBlue 'Choose an option:') "
    read a
	COLUMNS=12
    case $a in
	    1) installPre ; menu ;;
	    2) initialChecks ; menu ;;
	    3) checkUUID ; menu ;;
		4) flashFirmware ; menu ;;
	    5) all_checks ; menu ;;
		"q") exit 0 ;;
		"r") 
		if [[ $flashed == "1" ]]; then
			reboot; exit;
		else
			exit;
		fi
		exit ;;
		*) echo -e $red"Wrong option."$clear;;
    esac
}

initialChecks(){
	# Begin Checking For Devices FUNCTION
	header;
	echo "Running Checks for Cartographer Devices in Katapult Mode, DFU or USB"
	echo 
	# Check for canboot device
	canbootCheck=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep "CanBoot")
	if [[ $canbootCheck != "" ]]; then
		# Save CanBoot Device UUID
		canbootID=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -oP "canbus_uuid=\K.*" | sed -e 's/, Application: CanBoot//g')
		klippercheck=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -oP "canbus_uuid=${canbootID}, Application: Klipper")
	fi	
	# Check for Katapult device
	katapultCheck=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep "Katapult")
	if [[ $katapultCheck != "" ]]; then
		# Save Katapult Device UUID
		katapultID=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -oP "canbus_uuid=\K.*" | sed -e 's/, Application: Katapult//g')
		klippercheck=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -oP "canbus_uuid=${katapultID}, Application: Klipper")
	fi
	# Check for Device in DFU Mode Instead
	dfuCheck=$(lsusb | grep -oP "DFU Mode")
	if [[ $dfuCheck == "DFU Mode" ]]; then
		# Save DFU Device ID
		dfuID=$(lsusb | grep "DFU Mode" | awk '{print $6}');
	fi
	# Check For USB Serials
	if [ -d /dev/serial/by-id/ ]; then
		# Check for Cartographer USB
		usbCheck=$(ls -l /dev/serial/by-id/ | grep -oP "Cartographer")
			if [[ $usbCheck == "Cartographer" ]]; then
				# Save USB ID
				usbID=$(ls -l /dev/serial/by-id/ | grep "Cartographer" | awk '{print $9}');
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
	# Checks Users UUID and Put Device into Katapult Mode
	header;
	echo "Please enter your cartographer UUID"
	echo "found usually in your printer.cfg under [cartographer] or [scanner]"
	echo 
	echo "To go back: b"
	echo
	echo -n "UUID: "
	read -r uuid
	
	# If user entered a valid UUID
	if ! [[ $uuid == "b" ]]; then
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
}

flashFirmware(){
	# List Firmware for Found Device FUNCTION
	header;
	echo "Pick which firmware you want to install, if unsure ask on discord (https://discord.gg/yzazQMEGS2)"
	echo 
	# If found device is Katapult
	if [[ $canbootID != "" ]] || [[ $katapultID != "" ]]; then
		printf "${BLUE}Flashing via ${GREEN}KATAPULT${NC}\n\n"
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
		printf "${BLUE}Flashing via ${GREEN}USB${NC}\n\n"
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
	echo "DUMMY FLASHED with $firmwareFile"
	
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
		dfu-util -R -a 0 -s 0x08000000:leave -D $firmwareFile
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
}

disclaimer;

initialChecks;

menu;





