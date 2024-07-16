#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;36m'
NC='\033[0m' # No Color
clear
### Written by KrauTech (https://github.com/krautech)

### Credit to Esoterical (https://github.com/Esoterical)
### I used inspiration and snippet from his debugging script
### Thanks

printf "${GREEN}


   ____                  _             _____      _      ____      ____    _____   _____      _    
  / ___|   __ _   _ __  | |_    ___   |_   _|    / \    |  _ \    | __ )  | ____| |_   _|    / \   
 | |      / _  | | '__| | __|  / _ \    | |     / _ \   | |_) |   |  _ \  |  _|     | |     / _ \  
 | |___  | (_| | | |    | |_  | (_) |   | |    / ___ \  |  __/    | |_) | | |___    | |    / ___ \ 
  \____|  \__,_| |_|     \__|  \___/    |_|   /_/   \_\ |_|       |____/  |_____|   |_|   /_/   \_\
                                                                                                   


${NC}"
printf "${RED}CanBus Firmware Updater Script${NC} v0.1\n"
saved_uuid=""
disclaimer() {
	echo "*************"
	echo "* Attention *"
	echo "*************"
	echo
	echo "This script is designed to update your firmware with the beta firmware."
	echo ""
	printf "${RED}USE AT YOUR OWN RISK${NC}"
	echo ""
	echo "This script is available for review at: "
	printf "${BLUE}https://github.com/krautech/scripts/blob/main/cartoTAP_canbus_updater.sh${NC}\n\n"
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
echo ""
echo ""
check_uuid(){
	echo "###################################################################################"
	echo "Please enter your cartographer UUID"
	echo "found usually in your printer.cfg under [cartographer] or [scanner]"

	echo -n "UUID: "
	read -r uuid
	
	echo "You Entered" $uuid
	read -p "is this correct? y/n:" -n 1 -r
	echo    # (optional) move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		checkuuid=$(python3 ~/katapult/scripts/flashtool.py -i can0 -u $uuid -r | grep -s "Flash Success")
		if [[ $checkuuid == "Flash Success" ]]; then
			echo "UUID Check: Success"
		else
			echo "UUID Check Failed: ${checkuuid}"
		fi
	else
		check_uuid;
	fi
}



check_katapult(){
	echo "###################################################################################"
	echo "Checking device is in Katapult Mode"
	~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0
	saved_uuid=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 | grep -oP "canbus_uuid=\K.*" | sed -e 's/, Application: CanBoot//g')
	check_flash;
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

v2(){
	echo "###################################################################################"
	if [ -d ~/Carto_TAP/FW/V2 ]; then
		cd ~/Carto_TAP/FW/V2

		while true; do
			options=("500k" "1M" "I Dont know")

			echo "What is your CanBUS baudrate?"
			select opt in "${options[@]}"; do
				case $REPLY in
					1) 500k; break ;;
					2) 1m; break ;;
					3) break 2 ;;
					*) echo "What's that?" >&3
				esac
			done
			echo "Are we done flashing v2?"
			select opt in "Yes" "No"; do
				case $REPLY in
					1) break 2 ;;
					2) break ;;
					*) echo "Look, it's a simple question..." >&2
				esac
			done

		done
	else
		echo "You do not have V2"
	fi
}

v3(){
	echo "###################################################################################"
	if [ -d ~/Carto_TAP/FW/V3 ]; then
		cd ~/Carto_TAP/FW/V3

		while true; do
			options=("500k" "1M" "I Dont know")

			echo "What is your CanBUS baudrate?"
			select opt in "${options[@]}"; do
				case $REPLY in
					1) 500k; break ;;
					2) 1m; break ;;
					3) break 2 ;;
					*) echo "What's that?" >&3
				esac
			done
			echo "Are we done flashing v3?"
			select opt in "Yes" "No"; do
				case $REPLY in
					1) break 2 ;;
					2) break ;;
					*) echo "Look, it's a simple question..." >&2
				esac
			done

		done
	else
		echo "You do not have V3"
	fi
}

flash_probe(){
	echo "###################################################################################"
	while true; do
		options=("V2" "V3" "I Dont Know")

		echo "Which version of Cartographer do you have?"
		select opt in "${options[@]}"; do
			case $REPLY in
				1) v2; break ;;
				2) v3; break ;;
				3) exit; break ;;
				*) echo "What's that?" >&3
			esac
		done
		
		echo "Are we done flashing firmware?"
		select opt in "Yes" "No"; do
			case $REPLY in
				1) break 2 ;;
				2) break ;;
				*) echo "Look, it's a simple question..." >&2
			esac
		done

	done

}

check_flash(){
	echo "Do you want to flash your probe?"
	options=("Yes" "No")
		select opt in "${options[@]}"; do
			case $REPLY in
				1) flash_probe; break ;;
				2) break ;;
				*) echo "What's that?" >&2
			esac
		done

}

while true; do
	echo "###################################################################################"
    echo "Choose an option:"
	if [[ $saved_uuid == "" ]]; then
		options=("Check UUID" "Check Katapult Mode" "Quit")
		select opt in "${options[@]}"; do
			case $REPLY in
				1) check_uuid; break ;;
				2) check_katapult; break ;;
				3) exit; break ;;
				*) echo "What's that?" >&3
			esac
		done
	else
		options=("Check UUID" "Check Katapult Mode" "Flash Cartographer" "Quit")
		select opt in "${options[@]}"; do
			case $REPLY in
				1) check_uuid; break ;;
				2) check_katapult; break ;;
				3) flash_probe; break ;;
				4) exit; break ;;
				*) echo "What's that?" >&4
			esac
		done
	fi

    echo "Are we done with this script?"
    select opt in "Yes" "No"; do
        case $REPLY in
            1) break 2 ;;
            2) break ;;
            *) echo "Look, it's a simple question..." >&2
        esac
    done
done


cd ~



