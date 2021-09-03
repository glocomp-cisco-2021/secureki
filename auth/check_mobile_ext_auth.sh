#!/usr/bin/python
import os
import sys
import signal
import subprocess
import time

#time.sleep(3)
#print("fail")
#sys.exit(0)
debugflag = 0

IKEY=""
SKEY=""
HOST=""
os.environ['PYTHONPATH'] = '/home/appm/script/duo_client_python'

personid = os.sys.argv[1]

try:
	#cmd = '/usr/bin/python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/preauth --method POST username='+personid+' | grep device | grep -v devices'
	#if debugflag:
	#	print(cmd)
	#popen = subprocess.Popen( cmd, shell=True, stdout=subprocess.PIPE)
	#out, error = popen.communicate()
	#device = out.split("\"")[3]
	#if debugflag:
	#	print('device:',device)
	
	#cmd ='/usr/bin/python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth --method POST username='+personid+' device='+device+' factor=push ipaddr= async=1 | grep txid'
	#cmd ='/usr/bin/python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth --method POST username='+personid+' device=auto factor=push ipaddr= async=1 | grep txid'
	cmd ='/usr/bin/python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth --method POST username='+personid+' device=auto factor=push ipaddr='
	#if debugflag:
	#	print(cmd)
	#popen = subprocess.Popen( cmd, shell=True, stdout=subprocess.PIPE)
	#out, error = popen.communicate()
	#txid = out.split("\"")[3]
	#if debugflag:
	#	print('txid:',txid)

	#cmd ='/usr/bin/python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth_status --method GET txid='+txid+' | grep result'
	if debugflag:
		print(cmd)

	count = 0
	result = ''
	while True:
		if count > 3:
			break
		popen = subprocess.Popen( cmd, shell=True, stdout=subprocess.PIPE)
		out, error = popen.communicate()
		result = out.split("\"")[5]
		if debugflag:
			print('result:',result)
		if result != 'waiting':
			break
		count = count + 1
	if result == 'allow':
		print('success')
	else:
		print('fail')
except Exception as err:
	if debugflag:
		print("ERR:",err)
	sys.exit(-1)
