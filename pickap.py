#!/usr/bin/python

# Usage : python pickap.py [1]
# [1] = Network Card (ensure monitor mode is available)
import os
import subprocess
import sys

def sanitize_input(typeof, text):
	def integer(text):
		try:
			text = int(text)
			return "success"
		except:
			return "error"
	def string(text):
		try:
			text = str(text)
			return "success"
		except:
			return "error"
	if typeof == "int":
		return integer(text)
	elif typeof == "str":
		return string(text)

def pick_ap(netcard, net_user_boot_savefile):
	timeoutSeconds = 20
	lines = []
	os.system('rm -rf '+net_user_boot_savefile)
	os.system('airmon-ng start '+netcard)
	print('[+] Scanning APs...('+str(timeoutSeconds)+'s)')
	command1 = 'airodump-ng '+netcard+' 2>&1 | tee '+net_user_boot_savefile
	try:
		subprocess.check_output(command1, shell=True, timeout=timeoutSeconds) # save APs to local file
	except:
		with open(net_user_boot_savefile) as file:
			while (line := file.readline().rstrip()):
				lines.append(line)
	file.close()
	for i in range(0, len(lines)):
		print(str(i)+' : '+lines[i])
	while True:
		#try:
			os.system('sleep 2')
			choose_ap = input('\n[*] choose line/AP : ')
			if sanitize_input('int', choose_ap) == 'success':
				if int(choose_ap) <= len(lines):
					chosen_ap = str(lines[int(choose_ap)])
					ap_mac_bssid = chosen_ap[1:18]
					ap_channel = chosen_ap[48:50]
					ap_essid = chosen_ap[75:-1]
					break
				else:
					print('\n[-] Error, please retry')
			else:
				print('\n[-] Error, please retry')
		#except:
			#print('\n[-] Error, please retry'); exit(1)
	return ap_mac_bssid, ap_channel, ap_essid

def main():
	nc = str(sys.argv[1])
	chosen_ap = pick_ap(nc,"dump.txt")
	bssid_MAC = chosen_ap[0]
	channel = chosen_ap[1]
	essid = chosen_ap[2][0:32] # WPA2 ESSIDs can be <32 characters long

	# get rid of unnecessary blank space
	i = len(essid)-1
	while(i > 0):
		if essid[i] == ' ':
			pass
		else:
			essid = essid[0:i+1]
			break
		i-=1
	
	f = open("pickap_return","w")
	f.write(bssid_MAC+'\n'+channel+'\n'+essid+'\n')
	f.close()
	os.system('rm -rf dump.txt')

main()