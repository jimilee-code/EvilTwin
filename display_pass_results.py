#!/usr/bin/python
import os
import time

while(1):
	os.system("sleep 2; mysql --user=root --database=rogue_AP --execute='select * from wpa_keys;'")
	sec = time.time()
	print('[*]\t'+str(sec)+'s\t[*]')
