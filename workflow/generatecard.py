import os
import json
from appm.custom_logger import CustomLogger

CARD_CONTENT = ''
APPROVE_CODE = ''
REJECT_CODE = ''
DETAIL_CODE = ''
DATA = ''

def init():
    global CARD_CONTENT
    # with open('card_temp.json','r') as file:
    with open('/home/appm/mail/templates/card_temp.json','r') as file:
        CARD_CONTENT = file.read()

def generatecard():
    global DATA, CARD_CONTENT, APPROVE_CODE, REJECT_CODE, DETAIL_CODE
    jdata = json.loads(DATA)
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


if __name__ == '__main__':
    # global DATA, CARD_CONTENT, APPROVE_CODE, REJECT_CODE, DETAIL_CODE
    init()
    #DATA = os.sys.argv[1] # request details in json
    DATA = '''
    {"APPROVAL3_TYPE": "null", "REQUESTER_NAME": "recvemail", "SID": "-", "APPROVAL3_ID2_STATUS": "null", "APPROVAL3_ID1": "null", "APPROVAL3_ID2": "null", "ENDDATE": "2021-08-12 19:27:59", "APPROVAL2_TYPE": "null", "LEVELTYPE": 1, "APPROVAL_TRANS_STATUS": 0, "SEQ": 57, "USERTYPE": "null", "COMPANY": "null", "APPROVAL_PROCESS_admin": "APPROVAL1_ID1", "DEPT": "null", "APPROVAL1_ID2": "null", "APPROVAL1_ID1": "admin", "ACCOUNTID": "root", "APPROVALLEVEL": 1, "APPROVAL1_ID2_STATUS": "null", "APPROVALNAME": "sendmail", "APPROVAL2_ID1": "null", "APPROVAL2_ID2": "null", "APPROVAL2_ID2_STATUS": "null", "STRDATE": "2021-08-12 15:28:00", "REASON": "Server Patching", "PROGRESSTYPE": 0, "APPROVAL1_TYPE": "null", "DAYOFWEEK": "null", "APPROVAL3_ID1_STATUS": "null", "IPADDRS": "null", "HOSTNAME": "centos-d", "IPADDR": "192.168.99.117", "APPROVAL2_ID1_STATUS": "null", "FINAL_APPROVAL_ID": "null", "APPROVAL1_ID1_STATUS": 1, "APPROVALTYPE": 3, "REQUESTER_ID": "recvemail"}
    '''
    print(os.sys.argv)
    #code generated
    print('ex: ')
    print(os.sys.argv[2])
    print(os.sys.argv[3])
    print(os.sys.argv[4])
    APPROVE_CODE = os.sys.argv[2]
    REJECT_CODE = os.sys.argv[3]
    DETAIL_CODE = os.sys.argv[4]
    generatecard()
