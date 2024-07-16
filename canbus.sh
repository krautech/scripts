#!/bin/bash


### Written by KrauTech (https://github.com/krautech)

### Credit to Esoterical (https://github.com/Esoterical)
### I used inspiration and snippet from his debugging script
### Thanks

echo " 

   ____                  _     _____      _      ____      ____    _____   _____      _    
  / ___|   __ _   _ __  | |_  |_   _|    / \    |  _ \    | __ )  | ____| |_   _|    / \   
 | |      / _  | | '__| | __|   | |     / _ \   | |_) |   |  _ \  |  _|     | |     / _ \  
 | |___  | (_| | | |    | |_    | |    / ___ \  |  __/    | |_) | | |___    | |    / ___ \ 
  \____|  \__,_| |_|     \__|   |_|   /_/   \_\ |_|       |____/  |_____|   |_|   /_/   \_\


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

cd ~

enterUUID(){
	echo "###################################################################################"
	echo "Please enter your cartographer UUID"
	echo "found usually in your printer.cfg under [cartographer] or [scanner]"

	echo -n "UUID: "
	read -r uuid
}

enterUUID;

echo "You Entered" $uuid
read -p "is this correct? y/n:" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # do dangerous stuff
	echo "
	
	
	
	
	
	
	
	"
	echo $uuid
else
	enterUUID;
fi

