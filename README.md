<a href="http://glocomp.com" target="_blank"><img src="https://s3.amazonaws.com/cdn.freshdesk.com/data/helpdesk/attachments/production/62009499919/original/ic_launcher.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAS6FNSMY2RG7BSUFP%2F20210610%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20210610T020401Z&X-Amz-Expires=604800&X-Amz-SignedHeaders=host&X-Amz-Signature=8b0bd730da5533c31b18238924ec06ed3fbba44b04ba2767aa013cf266183e3a" alt="Glocomp_Cisco_2021"/></a>

# Overview
[![License](https://img.shields.io/badge/License-View%20License-orange)](http://www.glocomp.com/)

Our solution integrate with Cisco Duo and Webex Team Cards and Buttons.

- Cisco Duo to provide multifactor authentication
- Webex Team space to receive and display event notifications.
- Webex Team to perform access workflow
- Webex Team to receive policy violations notification card

# Featured Integrations
[![integration](https://github.com/glocomp-cisco-2021/secureki/blob/main/docs/integration.png)]

# Installation

OS System:
```
# pip install duo-client
# yum install curl

```
# Description
**auth/check_mobile_ext_auth.sh**  - To send Cisco Duo Push authentication to mobile device

**auth/check_web_otp.sh**          - To check Cisco Duo Passcode Authentication

**syslogs/syslog.sh**                 - To detect system logs and events and call curlsend.py to send the notification

**syslogs/curlsend.py**               - To send event notification or policy violations to Webex Teams



## Usage
Upload the scripts to OS. Edit the script to include Cisco Duo API Host, IKEY and SKEY.

IKEY=""
SKEY=""
HOST=""


To run the query, execute a command like the following:

```
$ ./check_mobile_ext_auth.sh <username>
$ ./check_web_otp.sh <username> <passcode>
$ python curlsend.py
$ python mainbots.py
```

## Contributing
Glocomp
Cisco
