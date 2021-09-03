#!/usr/bin/python
import os
import sys
import time
import cx_Oracle
import subprocess
import datetime
import curlsend

debugflag = 0
syslog_server_ip = '127.0.0.1'
syslog_server_port = '514'
max_seq = 0

DEBUG_FILE = '/home/irass/log/syslog.log'
LOG_DEBUG = open(DEBUG_FILE, "a+")
LOG_DEBUG.write("Syslog service start : "+str(datetime.datetime.now())+"\n")
LOG_DEBUG.flush()

#select login_events max seq
try:
	dbconn = cx_Oracle.connect('appm', 'appmadmin', 'XE')
	cursor = dbconn.cursor()
except Exception as err:
	if debugflag == 1:
		print(err)
	LOG_DEBUG.write("Database connect error : "+str(datetime.datetime.now())+"\n")
	LOG_DEBUG.write(str(err)+"\n")
	LOG_DEBUG.flush()
	sys.exit(-1)

cursor.execute("SELECT MAX(SEQ) FROM APPM.LOGIN_EVENTS",
	{
	}
)

try:
	event_max_seq = cursor.fetchall()[0][0]
	if debugflag == 1:
		print('event_max_seq:',event_max_seq)
except Exception as err:
	if debugflag == 1:
		print(err)
	LOG_DEBUG.write("LOGIN_EVENTS SEQ Number read error : "+str(datetime.datetime.now())+"\n")
	LOG_DEBUG.write(str(err)+"\n")
	LOG_DEBUG.flush()
	sys.exit(-1)	
#select login_trans max seq
cursor.execute("SELECT MAX(SEQ) FROM APPM.LOGIN_TRANS",
	{
	}
)
try:
	login_max_seq = cursor.fetchall()[0][0]
	if debugflag == 1:
		print('login_max_seq:',login_max_seq)
except Exception as err:
	if debugflag == 1:
		print(err)
	LOG_DEBUG.write("LOGIN_TRANS SEQ Number read error : "+str(datetime.datetime.now())+"\n")
	LOG_DEBUG.write(str(err)+"\n")
	LOG_DEBUG.flush()
	sys.exit(-1)

#select audit_trail max auditdate
cursor.execute("SELECT TO_CHAR(MAX(AUDITDATE),'mm-dd-yyyy hh24:mi:ss') FROM APPM.AUDIT_TRAIL",
        {
        }
)
try:
	auditdate_max = cursor.fetchall()[0][0]
	if debugflag == 1:
		print('auditdate_max:',auditdate_max)
except Exception as err:
	if debugflag == 1:
		print(err)
	LOG_DEBUG.write("AUDIT_TRAIL SEQ Number read error : "+str(datetime.datetime.now())+"\n")
	LOG_DEBUG.write(str(err)+"\n")
	LOG_DEBUG.flush()
	sys.exit(-1)

#event_max_seq = 1176
#login_max_seq = 6474
#auditdate_max = '10-25-2018 18:23:41'

while True:
	try:
		if debugflag == 1:
			print('event_max_seq:',event_max_seq)
		cursor.execute("SELECT SEQ,PERSONID,PERSONNAME,HOSTNAME,IPADDR,ACCOUNTID,CLIENT_IPADDR, PROTOCOL,EVENT_TYPE,COMMAND,SUCCESSFAILFLAG,TO_CHAR(EVENTDATE,'mm-dd-yyyy HH24:mi:ss') FROM APPM.LOGIN_EVENTS WHERE SUCCESSFAILFLAG != 1 AND SEQ > :v1 ORDER BY SEQ",
			{
				'v1' : int(event_max_seq),
			}
		)

		info = cursor.fetchall()
		for x in info:
			seq = x[0]
			personid = x[1]
			personname = x[2]
			hostname = x[3]
			ipaddr = x[4]
			accountid = x[5]
			client_ipaddr = x[6]
			protocol = x[7]
			event_type = x[8]
			command = x[9]
			successfailflag = x[10]
			eventdate = x[11]
			if debugflag == 1:
				print(seq,personid,personname,hostname,ipaddr,accountid,client_ipaddr, protocol,event_type,command,successfailflag,eventdate)
			#send syslog
			cmd = '/usr/bin/logger -n ' + syslog_server_ip + ' -T -P ' + syslog_server_port + ' \"'+eventdate+' '+personid+' '+personname+' '+hostname+' '+ipaddr+' '+accountid+' '+client_ipaddr+' '+ protocol+' '+event_type+' '+command+'\"'
			if debugflag == 1:
				print(cmd)
			popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
			out, error = popen.communicate()
			if debugflag == 1:
				print("logger out:",out)
			#webex
			payload = curlsend.getcontent1(eventdate, personid, personname, client_ipaddr, hostname+' '+ipaddr+' '+accountid+' '+client_ipaddr+' '+ protocol+' '+event_type+' '+command)
			cmd = """curl --request POST --url https://webexapis.com/v1/messages --header 'Authorization: Bearer <Key>' --header 'Content-Type: application/json' --data '"""\
			+ payload + "'"
			if debugflag == 1:
					print(cmd)
			popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
			out, error = popen.communicate()
			if debugflag == 1:
					print("logger out:",out)

			event_max_seq = seq
	except Exception as err:
		if debugflag == 1:
			print(err)
		LOG_DEBUG.write("EVENT_TRANS Exception error : "+str(datetime.datetime.now())+"\n")
		LOG_DEBUG.write(str(err)+"\n")
		LOG_DEBUG.flush()
		
		sys.exit(-1)
	
	try:
		if debugflag == 1:
			print('auditdate_max:',auditdate_max)
		
		cursor.execute("SELECT PERSONID,PERSONNAME,IPADDR,ACTION,TO_CHAR(AUDITDATE,'mm-dd-yyyy HH24:mi:ss') FROM APPM.AUDIT_TRAIL WHERE AUDITDATE > TO_DATE(:v1,'mm-dd-yyyy hh24:mi:ss') AND DETAIL LIKE ('%client=APPM Client%') ORDER BY AUDITDATE",
            {
                'v1' : auditdate_max,
            }
        )

		info = cursor.fetchall()
		for x in info:
			personid = x[0]
			personname = x[1]
			ipaddr = x[2]
			action = x[3]
			logindate = x[4]
			if debugflag == 1:
				print(personid,personname,ipaddr,action,logindate)
			#send syslog
			cmd = '/usr/bin/logger -n ' + syslog_server_ip + ' -T -P ' + syslog_server_port + ' \"'+logindate+' '+personid+' '+personname+' '+ipaddr+' '+ action+'\"'
			if debugflag == 1:
				print(cmd)
			popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
			out, error = popen.communicate()
			if debugflag == 1:
				print("logger out:",out)
			#webex
			payload = curlsend.getcontent(logindate, personid, personname, ipaddr, action)
			cmd = """curl --request POST --url https://webexapis.com/v1/messages --header 'Authorization: Bearer <Key>' --header 'Content-Type: application/json' --data '"""\
			+ payload + "'"
			if debugflag == 1:
				print(cmd)
			popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
			out, error = popen.communicate()
			if debugflag == 1:
				print("logger out:",out)

			auditdate_max = logindate
	except Exception as err:
		if debugflag == 1:
			print(err)
		LOG_DEBUG.write("AUDIT_TRAIL Exception error : "+str(datetime.datetime.now())+"\n")
		LOG_DEBUG.write(str(err)+"\n")
		LOG_DEBUG.flush()
		
		sys.exit(-1)
	
	try:
		if debugflag == 1:
			print('login_max_seq:',login_max_seq)
		
		cursor.execute("SELECT SEQ,PERSONID,PERSONNAME,HOSTNAME,IPADDR,ACCOUNTID,CLIENT_IPADDR, PROTOCOL,SUCCESSFAILFLAG,TO_CHAR(LOGINDATE,'mm-dd-yyyy HH24:mi:ss') FROM APPM.LOGIN_TRANS WHERE SEQ > :v1 ORDER BY SEQ",
            {
                'v1' : int(login_max_seq),
            }
        )

		info = cursor.fetchall()
		for x in info:
			seq = x[0]
			personid = x[1]
			personname = x[2]
			hostname = x[3]
			ipaddr = x[4]
			accountid = x[5]
			client_ipaddr = x[6]
			protocol = x[7]
			successfailflag = x[8]
			logindate = x[9]
			if debugflag == 1:
				print(seq,personid,personname,hostname,ipaddr,accountid,client_ipaddr, protocol,successfailflag,logindate)
			#send syslog
			cmd = '/usr/bin/logger -n ' + syslog_server_ip + ' -T -P ' + syslog_server_port + ' \"'+logindate+' '+personid+' '+personname+' '+hostname+' '+ipaddr+' '+accountid+' '+client_ipaddr+' '+ protocol+'\"'
			if debugflag == 1:
				print(cmd)
			popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
			out, error = popen.communicate()
			if debugflag == 1:
				print("logger out:",out)
			#webex
			payload = curlsend.getcontent(logindate, personid, personname, client_ipaddr, hostname+' '+ipaddr+' '+accountid+' '+protocol)
			cmd = """curl --request POST --url https://webexapis.com/v1/messages --header 'Authorization: Bearer <key>' --header 'Content-Type: application/json' --data '"""\
			+ payload + "'"
			if debugflag == 1:
				print(cmd)
			popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
			out, error = popen.communicate()
			if debugflag == 1:
				print("logger out:",out)

			login_max_seq = seq
	except Exception as err:
		if debugflag == 1:
			print(err)
		LOG_DEBUG.write("LOGIN_TRANS Exception error : "+str(datetime.datetime.now())+"\n")
		LOG_DEBUG.write(str(err)+"\n")
		LOG_DEBUG.flush()
		
	time.sleep(10)
