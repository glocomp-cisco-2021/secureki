#!/usr/bin/python
#-*- coding: utf-8 -*-

import os ,sys, inspect, signal, time, urllib
from subprocess import check_output

from appm.config import Configuration
from appm.custom_logger import CustomLogger
from appm.connection import Connection
from appm.commons_functions import *
import json

# 해당 스크립트 동작 전 필요한 변수 선언 및 자료 구조를 생성한다.
def script_init():
	# 변수 선언
	global log, CONFIG, LANG, CURSOR, CONTENT_TYPE, MAIL_TEMPLATE, AUTO_APPROVAL, SENDER_LIST, ONCE_APPROVAL, ONCE_APPROVAL_URL, APPROVED_URL_LIST
	# 변수 초기화 (초기화가 필요한 변수들)
	SENDER_LIST = {}
	ONCE_APPROVAL_URL = ''
	APPROVED_URL_LIST = {}

	tmp = Configuration(sys._getframe(), configfilename='mail.conf').get_data()
	CONFIG = tmp['MODULE']
	LANG = tmp['LANGUAGE'][CONFIG['LANGUAGE']]
	CONTENT_TYPE = CONFIG['MAIL']['MAIL_TYPE']['CONTENT_TYPE']
	AUTO_APPROVAL = CONFIG['MAIL']['ONCE_APPROVAL']['AUTO_APPROVAL']
	ONCE_APPROVAL = True if CONFIG['MAIL']['ONCE_APPROVAL']['USE_ONCE_URL'].upper() == 'ON' else False
	with open('/home/appm/mail/templates/template_temp.' + CONTENT_TYPE.lower(), 'r') as file: MAIL_TEMPLATE = file.read()

	if CONFIG['WORKFLOW']['WORK'].upper() == 'OFF': 
		print 'Apply the function in the setup file. file :/home/appm/mail/conf/mail.conf, WORKFLOW - WORK : ON'
		sys.exit(0)

	CURSOR = Connection().get_cursor()
	log = CustomLogger(sys._getframe(), \
		filelevel=CONFIG['LOG']['FILE_DEBUG_MODE'], \
		streamlevel=CONFIG['LOG']['STREAM_DEBUG_MODE']).get_logger()
		
# 메일 발송 스크립트 호출
# 실제 메일 발송 스크립트를 호출 한다.
def call_mail_script(subject, personid, requesterid):
	cmd = "/home/appm/mail/mail.sh '%s' '%s' 'template_%s.%s' '%s'" % (subject, personid, requesterid, CONTENT_TYPE.lower(), 'WORKFLOW')
	log.error('[SCRIPT CALL CMD] ' + cmd)
	os.system(cmd)

# 1회용 URL을 해당 WF 테이블의 로우에 업데이트 한다.
def update_approved_url():
        try:
                for seq in APPROVED_URL_LIST.keys():
                        URLS = ','.join(APPROVED_URL_LIST[seq])
                        CURSOR.execute("UPDATE WF_APPROVAL_TRANS SET ONCE_APPROVAL = :v1 WHERE SEQ = :v2", {'v1':URLS, 'v2':seq})

                Connection().commit_connection()
        except Exception as err:
                print repr(err)

# 메일 본문 테이블 헤더 생성 부분
# subject : 제목 유형
# content : 테이블의 내용 [LIST]
# approval_url : 자동 승인 주소
# RETURN_TEMPLATE : 데이터 테이블의 내용이 빠진 틀을 리턴 한다.
def create_column_header(subject, content, approval_url):
        log.error('tb body ' + content)
        log.error('approval_url ' + approval_url)
	RETURN_TEMPLATE = MAIL_TEMPLATE.replace('[LIST]', content).replace('[ONCE_APPROVAL]', approval_url) \
				.replace('[MAIL_HEADER]', LANG[subject]['MAIL_HEADER']) \
				.replace('[MAIL_HEADER_TITLE]', LANG[subject]['MAIL_HEADER_TITLE']) \
				.replace('[MAIL_HEADER_NAVI]', LANG[subject]['MAIL_HEADER_NAVI']) \
				.replace('[MAIL_HEADER_CONTENT]', LANG[subject]['MAIL_HEADER_CONTENT']) \
				.replace('[MAIL_BODY_TITLE]', LANG[subject]['MAIL_BODY_TITLE']) \
				.replace('[LINK_INFO]', LANG[subject]['LINK_INFO']) \
				.replace('[WEB_ADDRESS]', CONFIG['MAIL']['LINK']['APPM']) \
				.replace('[GUIDE_WORDS]', LANG['GUIDE']['MAIL']) \
				.replace('[APPROVAL_URL_MOVE_TITLE]', LANG['ONCE_APPROVAL']['APPROVAL_URL_MOVE_TITLE'])

	if ONCE_APPROVAL:
		RETURN_TEMPLATE = RETURN_TEMPLATE.replace('[APPROVAL_URL_TITLE]', LANG['ONCE_APPROVAL']['APPROVAL_URL_TITLE']) \
			.replace('[REJECTED_URL_TITLE]', LANG['ONCE_APPROVAL']['REJECTED_URL_TITLE'])

	# language.conf 의 MAIL_CONTENT_COLUMN에 정의 되어 있는 컬럼 제목을 html 태그로 생성한다.
	MAIL_CONTENT_COLUMN = ''
	for i in LANG[subject]['MAIL_CONTENT_COLUMN'].split(','):
		MAIL_CONTENT_COLUMN += CONFIG['MAIL']['CONTENTS_HEADER_COLUMNS'][CONTENT_TYPE.lower()] % i
	
	# 메일을 이용한 자동 승인/반려를 이용하는 경우 해당 링크를 생성할 테이블의 컬럼을 만들어 준다.
	if AUTO_APPROVAL == 'ON' and subject.find('REQ') != -1:
		MAIL_CONTENT_COLUMN += CONFIG['MAIL']['CONTENTS_HEADER_COLUMNS'][CONTENT_TYPE.lower()] % 'AUTO APPROVAL'

	RETURN_TEMPLATE = RETURN_TEMPLATE.replace('[MAIL_CONTENT_COLUMN]', MAIL_CONTENT_COLUMN)
	#log.error('[MAIL CONTENT]\n' + RETURN_TEMPLATE)
        log.error('approval url' + approval_url)
	return RETURN_TEMPLATE

def send_webex(data, approve, reject, once):
        CARD_CONTENT = ''
        APPROVE_CODE = approve
        REJECT_CODE = reject
        DETAIL_CODE = once
        DATA = data
        with open('/home/appm/mail/templates/card_temp.json','r') as file:
                CARD_CONTENT = file.read()
        jdata = data
        CARD_CONTENT = CARD_CONTENT.replace('[REQUESTER_NAME]', jdata['REQUESTER_NAME'])\
                .replace('[STRDATE]', jdata['STRDATE']) \
                .replace('[ENDDATE]', jdata['ENDDATE']) \
                .replace('[HOSTNAME]', jdata['HOSTNAME']) \
                .replace('[IPADDR]', jdata['IPADDR']) \
                .replace('[ACCOUNTID]', jdata['ACCOUNTID']) \
                .replace('[REASON]', jdata['REASON']) \
                .replace('[URL_APPROVE]', APPROVE_CODE) \
                .replace('[URL_REJECT]', REJECT_CODE) \
                .replace('[ONCE_URL]', DETAIL_CODE)
        tmpfile = '/tmp/%s_%s.json' % (jdata['HOSTNAME'],jdata['ACCOUNTID'])
        # tmpfile = './%s_%s.json' % (jdata['HOSTNAME'],jdata['ACCOUNTID'])
        with open(tmpfile,'w') as file:
                file.write(CARD_CONTENT)
        cmd = '''curl --request POST --url https://webexapis.com/v1/messages \
                --header 'Authorization: Bearer <ACCESS_TOKEN>' \
                --header 'Content-Type: application/json' -d @%s
              ''' % tmpfile
        log.error(cmd)
        os.system(cmd) # send card using curl
        os.system('rm -f %s' % tmpfile)


# 메일 본문 데이터 생성 부분
# subject : 제목 유형
# data : 생성해야 할 WF DATA(1 row)
def create_column_data(subject, data, recieverid):
        # log.error('data : ' + data)
        log.error('REQUESTER_NAME : ' + data['REQUESTER_NAME'])
        log.error('STRDATE : ' + data['STRDATE'])
        log.error('ENDDATE : ' + data['ENDDATE'])
        log.error('HOSTNAME : ' + data['HOSTNAME'])
        log.error('IPADDR : ' + data['IPADDR'])
        log.error('ACCOUNTID : ' + data['ACCOUNTID'])
        log.error('REASON : ' + data['REASON'])
        log.error('recieverid : ' + recieverid)
	try:
		tmp = ''
		for i in CONFIG['MAIL']['CONTENTS_COLUMNS'][subject]:
			tmp_column_data = data[i] if data[i] != None else ''
                        tmp += CONFIG['MAIL']['MAIL_CONTENT_TEMPLATE'][CONTENT_TYPE.lower()]['CONTENT_INSIDE'] % tmp_column_data
			
		if subject == 'USER_ADD_APPROVED': # 사용자 승인인 경우 임시 패스워드를 보내준다.
			tmp_passwd = recieverid + time.strftime("%m%d", time.localtime())
			tmp += CONFIG['MAIL']['MAIL_CONTENT_TEMPLATE'][CONTENT_TYPE.lower()]['CONTENT_INSIDE'] % tmp_passwd
		
		if ONCE_APPROVAL:
			ONCE_APPROVAL_URL = ''
			if 'APPROVAL_PROCESS_' + recieverid in data.keys():
				tmp_link = CONFIG['MAIL']['MAIL_CONTENT_TEMPLATE'][CONTENT_TYPE.lower()]['ONCE_APPROVAL_LINK'][AUTO_APPROVAL]
				cmd = cmd = '%s,%s,%s,' % (data['SEQ'], data['APPROVAL_PROCESS_' + recieverid], recieverid)
				DEFAULT_URL = check_output(['python /home/appm/mail/mailCrypto/urlAes.py ' + cmd + '3'], shell=True).strip()
			
	
				if data['SEQ'] in APPROVED_URL_LIST.keys():
					APPROVED_URL_LIST[data['SEQ']][DEFAULT_URL] = ''
				else:
					APPROVED_URL_LIST[data['SEQ']] = {DEFAULT_URL:''}

				ONCE_APPROVAL_URL = urllib.quote(DEFAULT_URL)

				if AUTO_APPROVAL == 'ON': # 자동 승인/반려인 경우
					APPROVED_URL = check_output(['python /home/appm/mail/mailCrypto/urlAes.py ' + cmd + '3,' + AUTO_APPROVAL], shell=True).strip()
					REJECTED_URL = check_output(['python /home/appm/mail/mailCrypto/urlAes.py ' + cmd + '2,' + AUTO_APPROVAL], shell=True).strip()
                                        log.error('AUTO_APPROVAL ' + 'APPROVE ' + urllib.quote(APPROVED_URL) + '::' + urllib.quote(REJECTED_URL))
                                        log.error('DEFAULT_URL / DETAILS : ' + ONCE_APPROVAL_URL)

					tmp_link = CONFIG['MAIL']['MAIL_CONTENT_TEMPLATE'][CONTENT_TYPE.lower()]['ONCE_APPROVAL_LINK'][AUTO_APPROVAL]
					tmp_link = tmp_link.replace('[APPROVED_URL]', urllib.quote(APPROVED_URL)).replace('[REJECTED_URL]', urllib.quote(REJECTED_URL))
					tmp += CONFIG['MAIL']['MAIL_CONTENT_TEMPLATE'][CONTENT_TYPE.lower()]['CONTENT_INSIDE'] % tmp_link
                                        send_webex(data, urllib.quote(APPROVED_URL), urllib.quote(REJECTED_URL), urllib.quote(DEFAULT_URL))

					APPROVED_URL_LIST[data['SEQ']][APPROVED_URL] = ''
					APPROVED_URL_LIST[data['SEQ']][REJECTED_URL] = ''

			else: # 반려 또는 승인 메일의 경우 1회용 이동 URL을 만들기 위해 아래 로직을 수행한다.
				tmp_link = CONFIG['MAIL']['MAIL_CONTENT_TEMPLATE'][CONTENT_TYPE.lower()]['ONCE_APPROVAL_LINK'][AUTO_APPROVAL]
				cmd = cmd = '%s,%s,%s,' % (data['SEQ'], '-', recieverid)
				DEFAULT_URL = check_output(['python /home/appm/mail/mailCrypto/urlAes.py ' + cmd + '3'], shell=True).strip()

				if data['SEQ'] in APPROVED_URL_LIST.keys():
                                        APPROVED_URL_LIST[data['SEQ']][DEFAULT_URL] = ''
                                else:
                                        APPROVED_URL_LIST[data['SEQ']] = {DEFAULT_URL:''}

                                ONCE_APPROVAL_URL = urllib.quote(DEFAULT_URL)

			SENDER_LIST[recieverid][subject]['ONCE_APPROVAL_URL'] = ONCE_APPROVAL_URL
	except Exception as err:
		log.error('[CREATE CONTENT PARAMETER] %s %s' % (subject, recieverid))
                log.error('[DATA ROW]\n' + str(data))
		log.error('[CREATE ROW]\n' + tmp)
		log.exception(err)
		sys.exit(0)
		
	return CONFIG['MAIL']['MAIL_CONTENT_TEMPLATE'][CONTENT_TYPE.lower()]['CONTENT_OUTSIDE'] % tmp

# 스크립트 메인 실행부	
if __name__ == '__main__':
	# 시작 : 인자값 받기
	# seq_list  : WF_APPROVAL_TRANS 테이블의 SEQ 번호. 여러개인 경우 ,(콤마) 로 구분.
	# SEND_TYPE : 메일을 실행 하는 시점으로 구분하며 0은 신청 1은 승인 또는 반려.
	seq_list = os.sys.argv[1]
	SEND_TYPE = os.sys.argv[2]
	
	# 1. 스크립트 초기화 
	script_init()
	log.error('[SCRIPT PARAMETER] [%s] [%s]' % (seq_list, SEND_TYPE))
	try:
		log.error('[STEP 1]=======================================================')
		# 2. 시퀀스 리스트 만큼 반복 실행하여 발송 대상자별로 본문 생성에 필요한 값을 구분하여 초기화한다.
		for i in seq_list.split(','):
			sql = '''SELECT A.SEQ,
			A.APPROVALNAME,
                        A.APPROVAL_TRANS_STATUS,
                        A.APPROVALTYPE,
                        A.LEVELTYPE,
                        A.PROGRESSTYPE,
                        A.APPROVALLEVEL,
                        A.REQUESTER_ID,
                        A.REQUESTER_NAME,
                        A.APPROVAL1_ID1,
                        A.APPROVAL1_ID2,
                        A.APPROVAL2_ID1,
                        A.APPROVAL2_ID2,
                        A.APPROVAL3_ID1,
                        A.APPROVAL3_ID2,
                        A.APPROVAL1_TYPE,
                        A.APPROVAL2_TYPE,
                        A.APPROVAL3_TYPE,
                        A.APPROVAL1_ID1_STATUS,
                        A.APPROVAL1_ID2_STATUS,
                        A.APPROVAL2_ID1_STATUS,
                        A.APPROVAL2_ID2_STATUS,
                        A.APPROVAL3_ID1_STATUS,
                        A.APPROVAL3_ID2_STATUS,
                        A.FINAL_APPROVAL_ID,
                        B.USERTYPE,
                        B.COMPANY,
                        B.DAYOFWEEK,
                        B.DEPT,
                        C.HOSTNAME,
                        C.IPADDR,
                        C.SID,
                        C.ACCOUNTID,
                        C.IPADDRS,
                        C.STRDATE,
                        C.ENDDATE,
                        D.REASON
			FROM WF_APPROVAL_TRANS A
			LEFT JOIN WF_PERSON_REQUEST B ON B.APPROVAL_TRANS_SEQ = A.SEQ
			LEFT JOIN WF_PWD_REQUEST C ON C.APPROVAL_TRANS_SEQ = A.SEQ
			LEFT JOIN REQUEST_REASON D ON D.SEQ = C.REQUEST_REASON_SEQ
			WHERE A.SEQ = :v1
			'''
			
			CURSOR.execute(sql, {'v1': i})
			data = Connection().rows_to_dict_list()[0]
		
			print data

			STATUS = data['APPROVAL_TRANS_STATUS']

			REQUESTERID = data['REQUESTER_ID']

			if data['APPROVAL_TRANS_STATUS'] == 3 and data['PROGRESSTYPE'] == 1 and data['FINAL_APPROVAL_ID'] != None:
				STATUS = 1 # 사후 승인인 경우 승인자에게 메일을 보내기 위해 상태를 진행 상태로 바꿔준다.
			subject = CONFIG['MAIL']['SUBJECTS'][STATUS][data['APPROVALTYPE']]
			
			log.error('[DB DATA]\n' + str(data))
			log.error('[MAIL TYPE] ' + subject)

			tmp_sender_list = [] # 메일 수신자 리스트가 임시로 저장될 공간
			# 신청 또는 진행인 경우
			if data['APPROVAL_TRANS_STATUS'] == 0 or data['APPROVAL_TRANS_STATUS'] == 1:
				# 단계별 승인 유형
				if data['LEVELTYPE'] == 2:
					for i in range(1, 4):
						# 사용자 신청, 사용자 1인 지정
						if data['APPROVAL' + str(i)+ '_TYPE'] == 1 or data['APPROVAL' + str(i)+ '_TYPE'] == 2:
							if data['APPROVAL' + str(i) + '_ID1_STATUS'] == 1:
								tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID1'])
								data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID1']] = 'APPROVAL' + str(i) + '_ID1'
								break

						# 단계별 승인 유형이 AND 또는 OR의 경우 승인권자 모두 진행 상태인 경우에만 메일을 발송 한다.
						if data['APPROVAL' + str(i)+ '_TYPE'] == 3 or data['APPROVAL' + str(i) + '_TYPE'] == 4:
							if data['APPROVAL' + str(i) + '_ID1_STATUS'] == 1 and data['APPROVAL' + str(i) + '_ID2_STATUS'] == 1:
								tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID1'])
								tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID2'])

								data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID1']] = 'APPROVAL' + str(i) + '_ID1'
								data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID2']] = 'APPROVAL' + str(i) + '_ID2'
								break

				# 수평적 승인 유형
				elif data['LEVELTYPE'] == 1:
					# 수평승인의 경우 모든 승인자가 진행중인 경우에만 메일을 발송 한다. > 최초 1회만 발송하기 위해.
					approval_id_count = 0
					approval_id_count += 1 if data['APPROVAL1_ID1'] != None else 0					
					approval_id_count += 1 if data['APPROVAL1_ID2'] != None else 0
					approval_id_count += 1 if data['APPROVAL2_ID1'] != None else 0
					approval_id_count += 1 if data['APPROVAL2_ID2'] != None else 0
					approval_id_count += 1 if data['APPROVAL3_ID1'] != None else 0
					approval_id_count += 1 if data['APPROVAL3_ID2'] != None else 0					

					progress_count = 0 
					progress_count += 1 if data['APPROVAL1_ID1_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL1_ID2_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL2_ID1_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL2_ID2_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL3_ID1_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL3_ID2_STATUS'] == 1 else 0
					
					if progress_count == approval_id_count:
						for i in range(1, 4):
							if data['APPROVAL' + str(i) + '_ID1'] != None and data['APPROVAL' + str(i) + '_ID1_STATUS'] == 1:
								tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID1'])
								data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID1']] = 'APPROVAL' + str(i) + '_ID1'

							if data['APPROVAL' + str(i) + '_ID2'] != None and data['APPROVAL' + str(i) + '_ID2_STATUS'] == 1:
								tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID2'])
								data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID2']] = 'APPROVAL' + str(i) + '_ID2'
			# 반려인 경우		
			elif data['APPROVAL_TRANS_STATUS'] == 2:
				tmp_sender_list.append(data['REQUESTER_ID'])
			# 승인인 경우
			elif data['APPROVAL_TRANS_STATUS'] == 3:

				# 단계별 승인 유형
                                if data['LEVELTYPE'] == 2:
                                        for i in range(1, 4):
                                                # 사용자 신청, 사용자 1인 지정
                                                if data['APPROVAL' + str(i)+ '_TYPE'] == 1 or data['APPROVAL' + str(i)+ '_TYPE'] == 2:
                                                        if data['APPROVAL' + str(i) + '_ID1_STATUS'] == 1:
                                                                tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID1'])
                                                                data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID1']] = 'APPROVAL' + str(i) + '_ID1'
								break

                                                # 단계별 승인 유형이 AND 또는 OR의 경우 승인권자 모두 진행 상태인 경우에만 메일을 발송 한다.
                                                if data['APPROVAL' + str(i)+ '_TYPE'] == 3 or data['APPROVAL' + str(i) + '_TYPE'] == 4:
                                                        if data['APPROVAL' + str(i) + '_ID1_STATUS'] == 1 and data['APPROVAL' + str(i) + '_ID2_STATUS'] == 1:
                                                                tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID1'])
                                                                tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID2'])

                                                                data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID1']] = 'APPROVAL' + str(i) + '_ID1'
                                                                data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID2']] = 'APPROVAL' + str(i) + '_ID2'
								break

				# 수평적 승인 유형
				elif data['LEVELTYPE'] == 1:
					# 수평승인의 경우 승인시에는 다른 승인자에게 메일 발송을 하지 않는다.
					# 단 사후승인의 경우 최초 1회를 보내기 위해 모든 사용자가 승인 진행중인 경우 메일 발송을 한다.
					approval_id_count = 0
                                        approval_id_count += 1 if data['APPROVAL1_ID1'] != None else 0
                                        approval_id_count += 1 if data['APPROVAL1_ID2'] != None else 0
                                        approval_id_count += 1 if data['APPROVAL2_ID1'] != None else 0
                                        approval_id_count += 1 if data['APPROVAL2_ID2'] != None else 0
                                        approval_id_count += 1 if data['APPROVAL3_ID1'] != None else 0
                                        approval_id_count += 1 if data['APPROVAL3_ID2'] != None else 0

					progress_count = 0
					progress_count += 1 if data['APPROVAL1_ID1_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL1_ID2_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL2_ID1_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL2_ID2_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL3_ID1_STATUS'] == 1 else 0
					progress_count += 1 if data['APPROVAL3_ID2_STATUS'] == 1 else 0
					
					if progress_count == approval_id_count:
						for i in range(1, 4):
							if data['APPROVAL' + str(i) + '_ID1'] != None and data['APPROVAL' + str(i) + '_ID1_STATUS'] == 1:
								tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID1'])
								data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID1']] = 'APPROVAL' + str(i) + '_ID1'

							if data['APPROVAL' + str(i) + '_ID2'] != None and data['APPROVAL' + str(i) + '_ID2_STATUS'] == 1:
								tmp_sender_list.append(data['APPROVAL' + str(i) + '_ID2'])
								data['APPROVAL_PROCESS_' + data['APPROVAL' + str(i) + '_ID2']] = 'APPROVAL' + str(i) + '_ID2'

				# 모든 승인자가 승인을 완료 하였을 경우 신청자에게 메일발송을 하기 위해 카운트를 센다.
				if data['FINAL_APPROVAL_ID'] != None and data['PROGRESSTYPE'] != 1:
					tmp_sender_list.append(data['REQUESTER_ID'])

			log.error('[TMP_SENDER_LIST] ' + str(tmp_sender_list))
			# 메일을 받는 수신자 리스트에 메일 본문을 생성 해야 할 데이터를 넣어준다.
			for user in tmp_sender_list:
				# 수신자 리스트에 해당 수신자의 자료가 있는 경우
				if user in SENDER_LIST.keys():
					
					# 해당 수신자의 데이터에 해당 메일 유형의 보낼 건수가 있는 경우
					if subject in SENDER_LIST[user].keys():
						SENDER_LIST[user][subject]['data'].append(data)
						
					# 해당 수신자의 데이터에 해당 메일 유형의 보낼 건수가 없는 경우
					else:
						SENDER_LIST[user][subject] = {'data':[data]}
						
				# 수신자 리스트에 해당 수신자의 자료가 없는 경우 해당 자료 구조를 만들어서 넣어준다.
				else:	
					SENDER_LIST[user] = { subject : {'data':[data]} }

		log.error('[STEP 2]=======================================================')
		# 3. 메일 발송 대상자 수 만큼 반복 실행 하여 메일 본문을 생성 한다.
		for user in SENDER_LIST:	# 메일 수신자
			for mailtype in SENDER_LIST[user]:	# 메일 발송 유형
				# 본문 테이블의 데이터 부분 생성[LIST]
				tmp_content = ''
				for content_db_data in SENDER_LIST[user][mailtype]['data']:
					tmp_content += create_column_data(subject, content_db_data, user)

				# 자동 승인 기능을 사용 하는 경우 생성된 링크를 HTML 태그로 변환 하여 변수에 담아준다.
				if 'ONCE_APPROVAL_URL' in SENDER_LIST[user][mailtype].keys():
					ONCE_APPROVAL_URL = CONFIG['MAIL']['MAIL_CONTENT_TEMPLATE'][CONTENT_TYPE.lower()]['ONCE_APPROVAL_LINK']['OFF'].replace('[APPROVED_URL]', SENDER_LIST[user][mailtype]['ONCE_APPROVAL_URL'])
                                        log.error('ONCE_APPROVAL_URL ' + SENDER_LIST[user][mailtype]['ONCE_APPROVAL_URL'])
			
				# 메일 발송을 하기 위한 템플릿은 생성한다.	
				final_content = create_column_header(mailtype, tmp_content, ONCE_APPROVAL_URL)

				tmp_name = '/home/appm/mail/template_' + REQUESTERID + '.' + CONTENT_TYPE.lower()
				# 생성된 메일 발송 템플릿을 파일로 저장한다.
				with open(tmp_name, 'w') as file: file.write(final_content)
				
				# 3-1. 생성 된 본문을 발송 한다.
				call_mail_script(mailtype, user, REQUESTERID)

				# 메일 발송 후 template_ 사용자id 파일 삭제
				if os.path.isfile(tmp_name):
					os.remove(tmp_name)
		
		# 4. 메일 발송 이후 워크플로우 URL을 DB의 로우에 업데이트 한다.
                update_approved_url()

	except Exception as err:
		lineno = sys.exc_info()[2].tb_lineno    # 에러 발생 라인번호
		try:
			log.exception(err)
		except:
			# logger 객체가 생성 되지 않은 경우
			print get_error_info(sys._getframe(), err, lineno=lineno)

	finally:
		Connection().destroyed_connection()



