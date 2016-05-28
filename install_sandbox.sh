#!/bin/bash

VMNAME="Hortonworks Sandbox with HDP 2.4"
OVA_FILE_URL="https://d1zjfrpe8p9yc0.cloudfront.net/hdp-2.4/HDP_2.4_virtualbox_v3.ova"
OVA_FILENAME="HDP_2.4_virtualbox_v3.ova"


# ANSI COLOR CODES
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function cleanUp ()
{
	echo
	printf "================= SHUTTING DOWN SANDBOX =================\n"
	VBoxManage controlvm "$VMNAME" poweroff
	exit 0
}

trap "cleanUp && exit 0" SIGINT SIGTERM

if ! type "brew" &> /dev/null; then
	printf "================= INSTALLING DEPENDENCY: HOMEBREW =================\n"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

if ! type "VBoxManage" &> /dev/null; then
	printf "\E[47;34m================= INSTALLING DEPENDENCY: VIRTUALBOX =================\n"
	brew tap Caskroom/cask
	brew cask install virtualbox
fi

if VBoxManage list vms | grep -q "$VMNAME" &> /dev/null; then
	printf "================= EXISTING SANDBOX FOUND =================\n"
	if VBoxManage list runningvms | grep -q "$VMNAME" &> /dev/null; then
		printf "${RED}ERROR${NC}: SANDBOX INSTANCE ALREADY RUNNING\n"
		exit 0
	fi
	VBoxManage startvm "$VMNAME" --type headless
else
	mkdir -p ~/Downloads
	cd ~/Downloads
	REMOTE_SIZE=$(curl -sI "$OVA_FILE_URL" | grep Content-Length | awk '{print $2}' | xargs)
	LOCAL_SIZE=$(wc -c "$OVA_FILENAME" | awk '{print $1}' | xargs)

	if [[ ! -f "$OVA_FILENAME" ]]; then
		printf "================= ${GREEN}DOWNLOADING SANDBOX ${NC} =================\n"
		curl -O "$OVA_FILE_URL" || exit 0
	elif [ "$REMOTE_SIZE"="$LOCAL_SIZE" ]; then
		printf "================= ${GREEN}DOWNLOADING SANDBOX ${NC} =================\n"
		curl -O "$OVA_FILE_URL" || exit 0
	fi
	printf "================= ${GREEN}IMPORTING OVA${NC} =================\n"
	VBoxManage import "$OVA_FILENAME"
	cd -
	VBoxManage startvm "$VMNAME" --type headless
fi

printf "================= ${GREEN}SANDBOX STARTED${NC} =================\n"
echo

echo "Starting Sandbox server..."

while true; do
	if [[ $? == 0 ]]; then
		echo "Server started - `date`"
		open http://127.0.0.1:8080
		break
	else
		curl http://127.0.0.1:8000 &>/dev/null
		sleep 1;
	fi
done

echo
echo "Credentials for Ambari Dashboard"
echo "Username: maria_dev"
echo "Password: maria_dev"
echo
echo "Other Sandbox components may still be loading"
echo

printf "Type 'end' or press CTRL-C to shut down the Sandbox.\n"

while read input; do
    if [ "$input" == "end" ]; then
    	cleanUp
		break
    fi
done < /dev/tty
