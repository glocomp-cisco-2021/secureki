import subprocess
from datetime import datetime

def getcontent(eventdate, personid, personname, clientip, hostaction):
    content = """{
      \"attachments\": [
        {
          \"contentType\": \"application/vnd.microsoft.card.adaptive\",
          \"content\": {
            \"type\": \"AdaptiveCard\",
            \"body\": [
              {
                \"type\": \"ColumnSet\",
                \"columns\": [
                  {
                    \"type\": \"Column\",
                    \"items\": [
                      {
                        \"type\": \"Image\",
                        \"url\": \"https://s3.amazonaws.com/cdn.freshdesk.com/data/helpdesk/attachments/production/62000358262/logo/Y2UUOZXTs_blFrPk-GY93pIkeEm4c5EFLw.png\"
                      }
                    ],
                    \"width\": \"auto\"
                  },
                  {
                    \"type\": \"Column\",
                    \"items\": [
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"SecureKi Alert\",
                        \"weight\": \"Lighter\",
                        \"color\": \"Accent\",
                        \"fontType\": \"Default\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"weight\": \"Bolder\",
                        \"text\": \"SecureKi Event\",
                        \"wrap\": true,
                        \"color\": \"Light\",
                        \"size\": \"Large\",
                        \"spacing\": \"Small\"
                      }
                    ],
                    \"width\": \"stretch\"
                  }
                ]
              },
              {
                \"type\": \"ColumnSet\",
                \"columns\": [
                  {
                    \"type\": \"Column\",
                    \"width\": 35,
                    \"items\": [
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"Event Date:\",
                        \"color\": \"Light\",
                        \"fontType\": \"Default\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"User ID:\",
                        \"weight\": \"Lighter\",
                        \"color\": \"Light\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"User Name:\",
                        \"weight\": \"Lighter\",
                        \"color\": \"Light\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"Client IP:\",
                        \"wrap\": true
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"Message:\",
                        \"wrap\": true
                      }
                    ]
                  },
                  {
                    \"type\": \"Column\",
                    \"width\": 65,
                    \"items\": [
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"eventdate\",
                        \"color\": \"Light\",
                        \"fontType\": \"Default\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"personid\",
                        \"color\": \"Light\",
                        \"weight\": \"Lighter\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"personname\",
                        \"weight\": \"Lighter\",
                        \"color\": \"Light\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"clientip\",
                        \"wrap\": true
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"hostaction\",
                        \"wrap\": true
                      }
                    ]
                  }
                ],
                \"spacing\": \"Padding\",
                \"horizontalAlignment\": \"Center\",
                \"style\": \"default\",
                \"bleed\": true
              }
            ],
            \"$schema\": \"http://adaptivecards.io/schemas/adaptive-card.json\",
            \"version\": \"1.2\"
          }
        }
      ],
      \"roomId\": \"Y2lzY29zcGFyazovL3VzL1JPT00vNjc0MjU3YjAtYjk1Mi0xMWViLTg1MjktOWIzMjZjY2MyZTA1\",
      \"text\": \" \"
    }""";
    content = content.replace("eventdate",eventdate)
    content = content.replace("personid",personid)
    content = content.replace("personname",personname)
    content = content.replace("clientip",clientip)
    content = content.replace("hostaction",hostaction)
    return content

def getcontent1(eventdate, personid, personname, clientip, hostaction):
    content = """{
      \"attachments\": [
        {
          \"contentType\": \"application/vnd.microsoft.card.adaptive\",
          \"content\": {
            \"type\": \"AdaptiveCard\",
            \"body\": [
              {
                \"type\": \"ColumnSet\",
                \"columns\": [
                  {
                    \"type\": \"Column\",
                    \"items\": [
                      {
                        \"type\": \"Image\",
                        \"url\": \"https://s3.amazonaws.com/cdn.freshdesk.com/data/helpdesk/attachments/production/62000358262/logo/Y2UUOZXTs_blFrPk-GY93pIkeEm4c5EFLw.png\"
                      }
                    ],
                    \"width\": \"auto\"
                  },
                  {
                    \"type\": \"Column\",
                    \"items\": [
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"SecureKi Alert\",
                        \"weight\": \"Lighter\",
                        \"color\": \"Accent\",
                        \"fontType\": \"Default\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"weight\": \"Bolder\",
                        \"text\": \"SecureKi Event\",
                        \"wrap\": true,
                        \"color\": \"Light\",
                        \"size\": \"Large\",
                        \"spacing\": \"Small\"
                      }
                    ],
                    \"width\": \"stretch\"
                  }
                ]
              },
              {
                \"type\": \"ColumnSet\",
                \"columns\": [
                  {
                    \"type\": \"Column\",
                    \"width\": 35,
                    \"items\": [
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"Event Date:\",
                        \"color\": \"Light\",
                        \"fontType\": \"Default\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"User ID:\",
                        \"weight\": \"Lighter\",
                        \"color\": \"Light\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"User Name:\",
                        \"weight\": \"Lighter\",
                        \"color\": \"Light\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"Client IP:\",
                        \"wrap\": true
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"Message:\",
                        \"wrap\": true
                      }
                    ]
                  },
                  {
                    \"type\": \"Column\",
                    \"width\": 65,
                    \"items\": [
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"eventdate\",
                        \"color\": \"Light\",
                        \"fontType\": \"Default\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"personid\",
                        \"color\": \"Light\",
                        \"weight\": \"Lighter\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"personname\",
                        \"weight\": \"Lighter\",
                        \"color\": \"Light\"
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"clientip\",
                        \"wrap\": true
                      },
                      {
                        \"type\": \"TextBlock\",
                        \"text\": \"hostaction\",
                        \"wrap\": true
                      }
                    ]
                  }
                ],
                \"spacing\": \"Padding\",
                \"horizontalAlignment\": \"Center\",
                \"style\": \"default\",
                \"bleed\": true
              }
            ],
            "actions": [
                {
                    "type": "Action.OpenUrl",
                    "title": "More Info",
                    "url": "https://appm.secureki.com/irass/login_trans_list.jsp"
                }
            ],
            \"$schema\": \"http://adaptivecards.io/schemas/adaptive-card.json\",
            \"version\": \"1.2\"
          }
        }
      ],
      \"roomId\": \"Y2lzY29zcGFyazovL3VzL1JPT00vNjc0MjU3YjAtYjk1Mi0xMWViLTg1MjktOWIzMjZjY2MyZTA1\",
      \"text\": \" \"
    }""";
    content = content.replace("eventdate",eventdate)
    content = content.replace("personid",personid)
    content = content.replace("personname",personname)
    content = content.replace("clientip",clientip)
    content = content.replace("hostaction",hostaction)
    return content

if __name__=="__main__":
    now = datetime.now()
    payload = getcontent(now.strftime("%Y-%m-%d %H:%M:%S"), "cchaic", "Chai Choon Cheng", "10.18.8.99", "centos7.5 10.18.1.145 skiadm 10.18.8.99 ssh BLOCK cat")
    cmd = """curl --request POST --url https://webexapis.com/v1/messages --header 'Authorization: Bearer <key>' --header 'Content-Type: application/json' --data '"""\
    + payload + "'"
    print(cmd)
    popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    out, error = popen.communicate()
