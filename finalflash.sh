#!/bin/bash
# Autor: Broly
# License: GNU General Public License v3.0
# https://www.gnu.org/licenses/gpl-3.0.txt
# This script is inteded to create a opencore usb-installer on linux 
# dependency gibmacos https://github.com/corpnewt/gibMacOS

RED="\033[1;31m\e[3m"
NOCOLOR="\e[0m\033[0m"

set -e

# Checking for root Identifying distro pkg-manager and installing dependencies.
if [[ $EUID -ne 0 ]]; then
	echo -e "${RED}This script must be executed as root!${NOCOLOR}"
	exit 1
fi

print() { echo -e   -- "$1\n"; }
log() { echo -e   -- "\033[37m LOG: $1 \033[0m\n"; }
success() { echo -e   -- "\033[32m SUCCESS: $1 \033[0m\n"; }
warning() { echo -e   -- "\033[33m WARNING: $1 \033[0m\n"; }
error() { echo -e   -- "\033[31m ERROR: $1 \033[0m\n"; }
heading() { echo -e   -- "   \033[1;30;42m $1 \033[0m\n\n"; }
banner() {
	clear
	echo "  ############################ "
	echo " # WELCOME TO FINALFLASH    # "
	echo "############################ "
	echo " "
	echo " "
}

ImportantTools(){
	banner
	echo -e "Installing p7zip wget and curl!"
	sleep 3s

	declare -A osInfo;
	osInfo[/etc/debian_version]="apt install -y"
	osInfo[/etc/alpine-release]="apk --update add"
	osInfo[/etc/centos-release]="yum install -y"
	osInfo[/etc/fedora-release]="dnf install -y"
	osInfo[/etc/arch-release]="pacman -S --noconfirm"

	for f in ${!osInfo[@]}
	do
		if [[ -f $f ]];then
			package_manager=${osInfo[$f]}
		fi
	done
	echo -e "Installing Depencencies..."
	package="wget curl p7zip"
	package1="wget curl p7zip"
	package2="wget curl p7zip-full"

	if [ "${package_manager}" = "pacman -S --noconfirm" ]; then
		${package_manager} ${package1}

	elif [ "${package_manager}" = "apt install -y" ]; then
		${package_manager} ${package2}

	elif [ "${package_manager}" = "yum install -y" ]; then
		${package_manager} ${package1}

	elif [ "${package_manager}" = "dnf install -y" ]; then
		${package_manager} ${package}

	else
		echo -e "${RED}Your distro is not supported!${NOCOLOR}"
		exit 1
	fi

  # Simple menu to select the Downloaded version of macOS only usefull if you download
  # multiple versions.
  banner
  #get the path
  echo -n "Please paste the recovery pkg path to extract:"
  read path
  npath=$(sed -e "s/^'//" -e "s/'$//" <<<"$path")
  cd "$npath"
  FILE=(RecoveryHDMetaDmg.pkg)
  FILE1=(*.RecoveryHDUpdate.pkg)
  if [ -f "$FILE" ]; then
	  echo "extracting $FILE..."
	  rm -rf *.hfs *.dmg
	  7z e -txar $FILE -bsp0 -bso0 *.dmg
	  7z e *.dmg -bsp0 -bso0 */Base*.dmg
	  7z e -tdmg Base*.dmg -bsp0 -bso0 *.hfs
	  mv *.hfs base.hfs
	  sleep 3s

  elif [ -f "$FILE1" ]; then
	  rm -rf *.hfs *.dmg
	  mv $FILE1 $FILE
	  7z e -txar $FILE -bsp0 -bso0 *.dmg
	  7z e *.dmg -bsp0 -bso0 */Base*.dmg
	  7z e -tdmg Base*.dmg -bsp0 -bso0 *.hfs
	  mv *.hfs base.hfs
	  sleep 3s
  else
	  echo -e "Please Download macOS with gibmacos!"
	  exit 1
  fi
}

# Move the recovery to /tmp delete everything in the current directory then bring it back.
teleport(){
	if
		mv $FILE /tmp/
		sleep 2s
	then
		rm -rf *.*
		mv /tmp/$FILE .
		sleep 2s
	else
		exit 1
	fi
}

# Here we partition the drive and dd the raw image to it.
partformat(){
	if
		umount $(echo /dev/$id?*) || :
		sleep 3s
		sgdisk --zap-all /dev/$id
		sgdisk /dev/$id --new=0:0:+300MiB -t 0:ef00
		partprobe $(echo /dev/$id?*)
	then
		sgdisk -e /dev/$id --new=0:0: -t 0:af00
		partprobe $(echo /dev/$id?*)
		sleep 3s
	else
		exit 1
	fi
}
burning(){
	banner
	if
		echo -e "Copying Image To Drive Be Patient..."
		dd bs=8M if="$PWD/base.hfs" of=$(echo /dev/$id)2 status=progress oflag=sync
		teleport
	then
		umount $(echo /dev/$id?*) || :
		sleep 3s
	else
		exit 1
		fi
	}

InstallOC(){
	banner
	# Format the EFI partition for opencore
	# and mount it in the /mnt.
	if
		mkfs.fat -F32 -n EFI $(echo /dev/$id)1
	then
		mount -t vfat  $(echo /dev/$id)1 /mnt/ -o rw,umask=000; sleep 3s
	else
		exit 1
	fi

  # Install opencore.
  echo -e "Installing OpenCore!!"
  sleep 3s

  # OpenCore Downloader fuction.

  if
	  curl "https://api.github.com/repos/acidanthera/OpenCorePkg/releases/latest" \
		  | grep -i browser_download_url \
		  | grep RELEASE.zip \
		  | cut -d'"' -f4 \
		  | wget -qi -
		    then
			    7z x *RELEASE.zip -bsp0 -bso0 -o/mnt/
		    else
			    exit 1
  fi
  sleep 5s
  chmod +x /mnt/
  rm -rf *RELEASE.zip
  umount $(echo /dev/$id)1
  mount -t vfat  $(echo /dev/$id)1 /mnt/ -o rw,umask=000
  sleep 3s
  banner
  echo -e "Installation finished, open /mnt and edit oc for your machine!!"
}
banner
# Print disk devices
# Read command output line by line into array ${lines [@]}
# Bash 3.x: use the following instead:
#   IFS=$'\n' read -d '' -ra lines < <(lsblk --nodeps -no name,size | grep "sd")
readarray -t lines < <(lsblk --nodeps -no name,size | grep "sd")

# Prompt the user to select the drive.
echo -e "${RED}WARNING: THE SELECTED DRIVE WILL BE ERASED!!!${NOCOLOR}"
echo -e "Please select the usb-drive!"
select choice in "${lines[@]}"; do
	[[ -n $choice ]] || { echo -e "${RED}>>> Invalid Selection!${NOCOLOR}" >&2; continue; }
	break # valid choice was made; exit prompt.
done
# Split the chosen line into ID and serial number.
read -r id sn unused <<<"$choice"
banner
while true; do
	read -p "$(echo -e "Drive ${RED}$id${NOCOLOR} will be erased, wget, curl and p7zip will be installed
do you wish to continue (y/n)? ")" yn
	case $yn in
		[Yy]* ) ImportantTools; partformat > /dev/null 2>&1 || :; burning; InstallOC; break;;
		[Nn]* ) exit;;
		* ) echo -e "Please answer yes or no.";;
	esac
done

