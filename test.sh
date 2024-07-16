#!/bin/bash



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