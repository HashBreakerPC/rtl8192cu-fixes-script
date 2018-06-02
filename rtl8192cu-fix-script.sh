#!/bin/bash
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  Copyright 2017 Paolo Cortese <dino.tartaro@gmail.com>
#  
#Compatibility
#These devices are known to work with this driver:
#ASUSTek USB-N13 rev. B1 (0b05:17ab)
#Belkin N300 (050d:2103)
#D-Link DWA-121 802.11n Wireless N 150 Pico Adapter [RTL8188CUS]
#Edimax EW-7811Un (7392:7811)
#Kootek KT-RPWF (0bda:8176)
#TP-Link TL-WN821Nv4 (0bda:8178)
#TP-Link TL-WN822N (0bda:8178)
#TP-Link TL-WN823N (only models that use the rtl8192cu chip)
#TRENDnet TEW-648UBM N150
#These devices are known not to be supported:
#Alfa AWUS036NHR
#TP-Link WN8200ND
#As a rule of thumb, this driver generally works with devices that use the RTL8192CU chipset, and some devices that use the RTL8188CUS, RTL8188CE-VAU and RTL8188RU chipsets too, though it's more hit and miss.
#Devices that use dual antennas are known not to work well. This appears to be an issue in the upstream Realtek driver.
#
#
#var
echo "Really IMPORTANT!!"
echo -ne "Remember to enable the sources (deb-src http://....)\nin the /etc/apt/sources.list file\n"
read -p "Continue with the installation? [y/n]: " inst
if [[ "$inst" != "y" ]]; then
	exit $?
	fi
dir=($HOME/.8192cu)
name=`uname -r`
#check dep
array=("dkms" "build-essential" "linux-headers-$name" "git")
for i in `seq 0 3`; do
	depc=`dpkg -s ${array[$i]} |awk '/Status/{print $3}' 2>/dev/null` 
	if [[ "$depc" != "ok" ]]; then
	#install dep
		echo "${array[$i]} dependency is not installed"
		echo "Installation of ${array[$i]}  dependency"
		sudo -p "Enter you user password: " apt-get update
		sudo -n apt-get install ${array[$i]} -y
		fi
	echo "Packages ${array[$i]} installed is: $depc"
	sleep 1
	done
#check old installation whith dkms
dri=`sudo dkms status 8192cu/1.11 | grep -o 'installed'`
if [[ "$dri" == "installed" ]]; then
	read -p "This driver is already installed, do you want to remove it now? [y/n]: " un
	if [[ "$un" == "y" ]]; then
		sudo -n dkms uninstall 8192cu/1.11 --all
		rm -f /etc/modprobe.d/blacklist-native-rtl8192.conf 2>/dev/null
		rm -f /etc/modprobe.d/8192cu-disable-power-management.conf 2>/dev/null
		echo "The driver was removed"
		sleep 5
		exit $?
		fi
		echo "Close the program nothing will be changed"
		sleep 5
		exit $?
	fi

#check internet connection
if ping -c 1 google.com >> /dev/null 2>&1; then
	echo "Clone git https://github.com/pvaret/rtl8192cu-fixes"
	if ! [ -d "$dir" ]; then
		mkdir "$dir"
		fi
		cd $dir
		git clone https://github.com/pvaret/rtl8192cu-fixes.git
		sudo -p "Enter you user password: " dkms add ./rtl8192cu-fixes
		sleep 1
		sudo -n dkms install 8192cu/1.11
		sleep 1
		sudo -n depmod -a
		sleep 1
		sudo -n cp ./rtl8192cu-fixes/blacklist-native-rtl8192.conf /etc/modprobe.d/
		sleep 1
		sudo -n cp ./rtl8192cu-fixes/8192cu-disable-power-management.conf /etc/modprobe.d/
		read -p "reboot your machine NOW? [y/n]: " ans
	if [[ "$ans" == "y" ]]; then
		sudo -n reboot
		else
		echo "Remember to restart your machine to make the changes effective"
		echo "Thanks P. Varet for drivers"
		echo "https://github.com/pvaret"
		sleep 8
		fi
	else
	echo "Check your internet connection"
	echo "and launch another instance..!"
	echo "           EXIT..."
	sleep 4
	fi
exit $?
