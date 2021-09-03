import os
import subprocess

IKEY=""
SKEY=""
HOST=""
#os.environ['PYTHONPATH'] = '/home/appm/script/duo_client_python'
#os.environ['PYTHONPATH'] = r'./duo_client_python'
personid='<PERSON_ID>'
debugflag=1

def check_duo(personid=personid):
	try:
		cmd ='python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth --method POST username='+personid+' device=auto factor=push ipaddr= async=1 | grep txid'
		# cmd ='python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth --method POST username='+personid+' device=auto factor=push ipaddr= async=1 | findstr txid'
		if debugflag:
			print(cmd)
		popen = subprocess.Popen( cmd, shell=True, stdout=subprocess.PIPE, text=True)
		out, error = popen.communicate()
		txid = out.split("\"")[3]
		if debugflag:
			print('txid:',txid)

		cmd ='python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth_status --method GET txid='+txid+' | grep result'
		# cmd ='python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth_status --method GET txid='+txid+' | findstr result'
		if debugflag:
			print(cmd)

		count = 0
		result = ''
		while True:
			if count > 3:
				break
			popen = subprocess.Popen( cmd, shell=True, stdout=subprocess.PIPE, text=True)
			out, error = popen.communicate()
			result = out.split("\"")[3]
			if debugflag:
				print('result:',result)
			if result != 'waiting':
				break
			count = count + 1
		if result == 'allow':
			print('success')
			return True
		else:
			print('fail')
			return False
	except Exception as err:
		if debugflag:
			print("ERR:",err)
		return False
