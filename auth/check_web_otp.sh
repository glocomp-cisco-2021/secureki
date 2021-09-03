#!/usr/bin/python
#-*- coding:utf-8 -*-


import os
import sys
import time
import signal
import datetime
import cx_Oracle
import subprocess
from subprocess import check_output

########## DUO Authentication #################
IKEY=""
SKEY=""
HOST=""
os.environ['PYTHONPATH'] = '/home/appm/script/duo_client_python'

##### Start define log file  #####
PROCESS_NAME = "CHECKWEBOTP"

# 로그파일에 사용될 시간값 (실시간:%Y%m%d%H%M%S, 일별:%Y%m%d, 월별:%Y%m ...)
PROCESS_TIME = time.strftime("%Y%m", time.localtime())

PROCESS_TODAY = time.strftime("%Y%m%d", time.localtime())
MAIN_DIRECTORY = "/home/appm/script"
LOG_DIRECTORY = "%s/log" % (MAIN_DIRECTORY)

# 환경설정파일이 필요한 경우에 사용 - def check_config()
#CONF_FILE = "%s/conf/default_%s.conf" % (MAIN_DIRECTORY, PROCESS_NAME.lower())

DEBUG_FILE = "%s/%s_%s.log" % (LOG_DIRECTORY, PROCESS_NAME, PROCESS_TIME)
if not os.path.isdir(LOG_DIRECTORY):
	try:
		os.mkdir(LOG_DIRECTORY)
	except:
		LOG_DIRECTORY = "/tmp"

##### End define log file  #####


##### Start define log flag  #####
_ERROR = 0
_DEBUG = 1
##### End define log flag  #####


##### Debug on/off #####
DEBUGFLAG = "ON"
#DEBUGFLAG = "OFF"
##### End define log flag  #####


# Open Log File
LOG_DEBUG = open(DEBUG_FILE, "a+")


def process_close():
	try:
		LOG_DEBUG.close()
		APPM_CURSOR.close()
		APPM_CONN.close()
	except:
		pass
	

	sys.exit()


def check_time():
	CHECK_TIME = datetime.datetime.now()
	return CHECK_TIME


def get_function_info(text):
	try:
		line_number = "%d" % (sys._getframe(1).f_lineno)
		function_name = "%s()" % (sys._getframe(1).f_code.co_name)
	except:
		line_number = 0
		function_name = "non"
		
	if text != "":
		error_message = str(text).rstrip("\n")
	else:
		error_message = ""
		
		
	return (line_number, function_name, error_message)
	

def debug_log(text, flag):
	# flag - 0:error, 1:debug
	
	if flag:
		COMP_TEXT = "[%s]DEBUG - %s" % (check_time(), text)

		LOG_DEBUG.write(COMP_TEXT + "\n")
		LOG_DEBUG.flush()
	else:
		COMP_TEXT = "[%s]ERROR - %s" % (check_time(), text)

		LOG_DEBUG.write(COMP_TEXT + "\n")
		LOG_DEBUG.flush()
		
		
		print "fail"
		

		process_close()
		
		
def timeout_handler(signum, frame):
	lineno, funcname, error = get_function_info("")
	MSG = "ERROR! - timeout_handler operation. (l:%s, f:%s, [%s])" % (lineno, funcname, error)
	debug_log(MSG, _ERROR)

	process_close()


def decrypt_password(cipher_text):
	return_text = ""
	
	try:
		command = "java -jar /home/appm/crypto/AesCrypto.jar decode %s" % (cipher_text)
		return_text = check_output([command], shell=True).strip()
	except Exception as err:
		lineno, funcname, error = get_function_info(err)
		MSG = "Failed to decrypt password. (l:%s, f:%s, [%s])" % (lineno, funcname, error)
		debug_log(MSG, _DEBUG)
		debug_log("", _DEBUG)


	return return_text


def encrypt_password(plain_text):
	return_text = ""
	
	try:
		command = "/home/appm/script/sha256sum.sh '%s'" % (plain_text)
		return_text = check_output([command], shell=True).strip()
	except Exception as err:
		lineno, funcname, error = get_function_info(err)
		MSG = "Failed to encrypt password. (l:%s, f:%s, [%s])" % (lineno, funcname, error)
		debug_log(MSG, _DEBUG)
		debug_log("", _DEBUG)
		

	return return_text


def check_config():
	global APPM_SID
	global APPM_USER
	global APPM_PASSWORD
	
	global TIME_OUT
	global LIMIT_COUNT
	global LIMIT_DELETE_COUNT


	if not os.path.exists(CONF_FILE):
		MSG = "Failed to not found config file. - %s" % (CONF_FILE)
		debug_log(MSG, _ERROR)

	else:
		TIME_OUT		= 0
		LIMIT_COUNT	= 0
		LIMIT_DELETE_COUNT	= 0

		try:
			parser = SafeConfigParser()
			parser.read(CONF_FILE)
		except Exception as err:
			lineno, funcname, error = get_function_info(err)
			MSG = "Failed to read config file. (l:%s, f:%s, [%s])" % (lineno, funcname, error)
			debug_log(MSG, _ERROR)

		try:
			APPM_SID	= parser.get('appm_config', 'sid')
			APPM_USER	= parser.get('appm_config', 'user')
			
			TMP_APPM_PASSWORD	= parser.get('appm_config', 'password')
			APPM_PASSWORD	= decrypt_password(TMP_APPM_PASSWORD)

			TIME_OUT		= int(parser.get('appm_config', 'timeout'))
			LIMIT_COUNT	= int(parser.get('appm_config', 'limit_count'))
			LIMIT_DELETE_COUNT	= int(parser.get('appm_config', 'limit_delete_count'))
		except Exception as err:
			lineno, funcname, error = get_function_info(err)
			MSG = "Failed to invalid config file. (l:%s, f:%s, [%s])" % (lineno, funcname, error)
			debug_log(MSG, _DEBUG)
			MSG = "sid:%s,user:%s,password:%s,timeout:%d,limit:%d,limit_delete:%d" % (APPM_SID, APPM_USER, APPM_PASSWORD, TIME_OUT, LIMIT_COUNT, LIMIT_DELETE_COUNT)
			debug_log(MSG, _ERROR)


		MSG = "APPM_SID:%s" % (APPM_SID)
		debug_log(MSG, _DEBUG)
		MSG = "APPM_USER:%s" % (APPM_USER)
		debug_log(MSG, _DEBUG)
		MSG = "APPM_PASSWORD:%s" % (APPM_PASSWORD)
		debug_log(MSG, _DEBUG)
		MSG = "TIME_OUT:%d" % (TIME_OUT)
		debug_log(MSG, _DEBUG)
		MSG = "LIMIT_COUNT:%d" % (LIMIT_COUNT)
		debug_log(MSG, _DEBUG)
		MSG = "LIMIT_DELETE_COUNT:%d" % (LIMIT_DELETE_COUNT)
		debug_log(MSG, _DEBUG)
		debug_log("", _DEBUG)
		
		
def database_connect():
	global APPM_CURSOR
	global APPM_CONN

	
	APPM_USER = 'appm'
	APPM_SID = 'XE'
	DBMS = "APPM"

	command = "/home/appm/script/decrypt_passwd"
	APPM_PASSWORD = check_output([command], shell=True).strip()

	try:
		APPM_CONN = cx_Oracle.connect(APPM_USER, APPM_PASSWORD, APPM_SID)
		APPM_CURSOR = APPM_CONN.cursor()
	except Exception as err:
		lineno, funcname, error = get_function_info(err)
		MSG = "Failed to %s database connect. (l:%s, f:%s, [%s])" % (DBMS, lineno, funcname, error)
		debug_log(MSG, _ERROR)
		

def check_appm_otp():
	TMP_RESULT = ""
	
	try:
		#COMMAND = "java -jar /home/appm/otp/botp/APPM_BOTP_SERVER.jar %s %s " % (OTPKEY, PERSONCODE)
		COMMAND = "java -cp /home/appm/otp/totp totpclient %s %s " % (OTPKEY, PERSONCODE)
		TMP_RESULT = check_output([COMMAND], shell=True).strip()
	except Exception as err:
		lineno, funcname, error = get_function_info(err)
		MSG = "Failed to execute otp module. (l:%s, f:%s, [%s])" % (lineno, funcname, error)
		debug_log(MSG, _DEBUG)
		debug_log("", _DEBUG)
		
	return TMP_RESULT
		
		
def check_other_otp():
	TMP_RESULT = "fail|Fail Message"
	
	try:
		COMMAND = "java -cp /home/appm/otp/totp totpclient %s %s " % (OTPKEY, PERSONCODE)
		TMP_RESULT = check_output([COMMAND], shell=True).strip()
	except Exception as err:
		lineno, funcname, error = get_function_info(err)
		MSG = "Failed to execute otp module. (l:%s, f:%s, [%s])" % (lineno, funcname, error)
		debug_log(MSG, _DEBUG)
		debug_log("", _DEBUG)
		
	return TMP_RESULT

def check_duo_auth():
	debugflag = 0
	
	TMP_RESULT = ""

	if PERSONCODE.lower() == 'none' or PERSONCODE.lower() == 'push':
		COMMAND = '/usr/bin/python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth --method POST username='+PERSONID+' device=auto factor=push ipaddr= async=1 | grep txid'
		if debugflag:
			print(COMMAND)	
		popen = subprocess.Popen( COMMAND, shell=True, stdout=subprocess.PIPE)
		out, error = popen.communicate()
		txid = out.split("\"")[3]
		if debugflag:
			print('txid:',txid)

		COMMAND = '/usr/bin/python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth_status --method GET txid='+txid+' | grep result'
		if debugflag:
			print(COMMAND)
		
	else:
		COMMAND = '/usr/bin/python -m duo_client.client --ikey '+IKEY+' --skey '+SKEY+' --host '+HOST+' --path /auth/v2/auth --method POST username='+PERSONID+' factor=passcode passcode='+PERSONCODE+' | grep result'	
		if debugflag:
			print(COMMAND)	

	count = 0
	result = ''
	while True:
		if count > 3:
			break
		popen = subprocess.Popen( COMMAND, shell=True, stdout=subprocess.PIPE)
		out, error = popen.communicate()
		result = out.split("\"")[3]
		if debugflag:
			print('result:',result)	
		if result != 'waiting':
			break
		count = count + 1

	if result == 'allow':
		TMP_RESULT = 'success'
	else:
		TMP_RESULT = 'fail'

	return TMP_RESULT

def main():
	global PERSONID
	global PERSONCODE
	global OTPKEY
	
	#if len(os.sys.argv[:]) != 3:
	#	MSG = "Invalid script argument. values(personid, personcode) [len(arg,3):%d]" % (len(os.sys.argv[:]))
	#	debug_log(MSG, _ERROR)


	PERSONID = os.sys.argv[1]
	PERSONCODE = os.sys.argv[2]
	
	
	if DEBUGFLAG == "ON":
		MSG = "personid:%s, personcode:%s" % (PERSONID, PERSONCODE)
		debug_log(MSG, _DEBUG)


	# database connection
	database_connect()
	

	TABLE_NAME = "APPM.PERSON"
		
	try:
		APPM_CURSOR.execute("SELECT NVL(AUTHTYPE, '-'), NVL(OTPTYPE, 0), NVL(OTPKEY, '-'), NVL(SMSCODE, '-'), NVL(TEMP_AUTHCODE,'-') FROM APPM.PERSON WHERE PERSONID = :v1",
			{
				'v1' : PERSONID
			}
		)
	except Exception as err:
		lineno, funcname, error = get_function_info(err)
		MSG = "Failed to select %s (l:%s, f:%s, [%s])" % (TABLE_NAME, lineno, funcname, error)
		debug_log(MSG, _ERROR)
		
	AUTHTYPE, OTPTYPE, OTPKEY, SMSCODE,TEMP_AUTHCODE  = APPM_CURSOR.fetchone()
	if TEMP_AUTHCODE != "-":
		if TEMP_AUTHCODE == PERSONCODE:
			if DEBUGFLAG == "ON":
				MSG = "TEMP_AUTHCODE:%s OK" % (TEMP_AUTHCODE)
				debug_log(MSG, _DEBUG)

			
			# End authentication
			print "success"
			sys.exit(0)
			
	if AUTHTYPE == None or AUTHTYPE == "-":
		MSG = "Not found authtype. [personid:%s]" % (PERSONID)
		debug_log(MSG, _ERROR)
		
		
	if DEBUGFLAG == "ON":
		MSG = "authtype:%s, otptype:%s(0:appm,1:other), otpkey:%s, smscode:%s" % (AUTHTYPE, str(OTPTYPE), OTPKEY, SMSCODE)
		debug_log(MSG, _DEBUG)
		
		
	if AUTHTYPE.lower() == "otp":
		if OTPTYPE == 0:
			RESULT = check_appm_otp()
		else:
			RESULT = check_other_otp()

	elif AUTHTYPE.lower() == "sms" or AUTHTYPE.lower() == "email" or AUTHTYPE.lower() == "msg":
		if SMSCODE == PERSONCODE:
			RESULT = "success"
			
			TABLE_NAME = "APPM.PERSON"
		
			try:
				APPM_CURSOR.execute("UPDATE APPM.PERSON SET SMSCODE = '' WHERE PERSONID = :v1",
					{
						'v1' : PERSONID
					}
				)
				
				APPM_CONN.commit()
			except Exception as err:
				lineno, funcname, error = get_function_info(err)
				MSG = "Failed to update %s (l:%s, f:%s, [%s])" % (TABLE_NAME, lineno, funcname, error)
				debug_log(MSG, _DEBUG)
			
			
		else:
			RESULT = "fail"
		
	elif AUTHTYPE.lower() == "mobile":
		RESULT = check_duo_auth()
	
	else:
		MSG = "Invalid authtype. [personid:%s, authtype:%s]" % (PERSONID, AUTHTYPE)
		debug_log(MSG, _ERROR)
	
	
	if DEBUGFLAG == "ON":
		MSG = "result:%s" % (RESULT)
		debug_log(MSG, _DEBUG)

	
	# End authentication
	print RESULT
	


signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm(60)


# main
main()
