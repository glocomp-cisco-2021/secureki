# Overview
[![License](https://img.shields.io/badge/License-View%20License-orange)](http://www.glocomp.com/)

Our solution integrate with Cisco Duo and Webex Team Cards and Buttons.

- Cisco Duo to provide multifactor authentication
- Webex Team space to receive and display event notifications.
- Webex Team to perform access workflow
- Webex Team to receive policy violations notification card

# Featured Integrations
![integration](https://github.com/glocomp-cisco-2021/secureki/blob/main/docs/integration.png)

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

