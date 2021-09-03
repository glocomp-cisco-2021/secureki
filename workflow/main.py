from webexteamssdk import WebexTeamsAPI as webex
from webexteamssdk import ApiError
from webexteamssdk.models.cards import AdaptiveCard
from webexteamssdk.models.cards.inputs import Text, Number
from webexteamssdk.models.cards.components import Column, TextBlock, Image
from webexteamssdk.models.cards.actions import Submit, OpenUrl
from webexteamssdk.models.cards.container import ColumnSet
from webexteamssdk.models.cards.options import HorizontalAlignment, ImageSize, ImageStyle


api = webex(access_token='MWQ0ZDI3NGEtOWFlYS00Y2JkLTgyMjItYzBhZDIxYThkMmI4MWU4ZTE0MWUtYmVl_PF84_f3d80159-67d0-4b1c-994e-6c7aa6bc2c1d')

def sendmessage(roomid, message):
    try:
        message = api.messages.create(roomid, text=message)
        print("New message created, with ID:", message.id)
        print(message.text)
    except ApiError as e:
        print(e)

def showrooms(roomTitle = 'Sample'):
    all_rooms = api.rooms.list()
    # TODO: we return all room that match?
    # [room for room in all_rooms if 'webexteamssdk Demo' in room.title]
    for room in all_rooms:
        if room and roomTitle in room.title:
            return room

def sendcard(requestor, reason, approve_url, reject_url, details_url):
    try:
        greeting = TextBlock("Hey hello there! I am a adaptive card")
        first_name = Text('first_name', placeholder="First Name")
        age = Number('age', placeholder="Age")
        submit = Submit(title="Send me!")
        logo = Image(
            url= 'https://s3.amazonaws.com/cdn.freshdesk.com/data/helpdesk/attachments/production/62000358262/logo/Y2UUOZXTs_blFrPk-GY93pIkeEm4c5EFLw.png',
            altText= 'logo',
            style= ImageStyle(ImageStyle.DEFAULT),
            horizontalAlignment= HorizontalAlignment(HorizontalAlignment.LEFT),
            size= ImageSize(ImageSize.MEDIUM),
            height='50px'
        )
        col0101 = Column(items=[logo],width='auto')
        title = TextBlock('Cisco Webex Teams')
        message = TextBlock('Buttons and Cards Release', size='Large', weight='Bolder', color='Light')
        col0102 = Column(items=[title, message])
        colset01 = ColumnSet(columns=[col0101, col0102])
        # Available Action
        approve = Submit(
            title= 'Approve',
            data= f'''{{'action':'approve', 'target':'{approve_url}'}}'''
        )
        reject = Submit(
            title= 'Reject',
            data= f'''{{'action':'reject', 'target':'{reject_url}'}}'''
        )
        #use hardcode link for demo
        portal = OpenUrl(
            url= 'https://<IPADDR>:8443/OnceApproval?'+details_url,
            title= 'More...'
        )
        card = AdaptiveCard(body=[colset01], actions=[approve, reject, portal])
        message = api.messages.create(room.id,text='approval require', attachments=[card])
        print("New message created, with ID:", message)
        print(message.text)
    except ApiError as e:
        print(e)

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    room = showrooms()
    try:
        greeting = TextBlock("Hey hello there! I am a adaptive card")
        first_name = Text('first_name', placeholder="First Name")
        age = Number('age', placeholder="Age")
        submit = Submit(title="Send me!")
        logo = Image(
            url= 'https://s3.amazonaws.com/cdn.freshdesk.com/data/helpdesk/attachments/production/62000358262/logo/Y2UUOZXTs_blFrPk-GY93pIkeEm4c5EFLw.png',
            altText= 'logo',
            style= ImageStyle(ImageStyle.DEFAULT),
            horizontalAlignment= HorizontalAlignment(HorizontalAlignment.LEFT),
            size= ImageSize(ImageSize.MEDIUM),
            height='50px'
        )
        col0101 = Column(items=[logo],width='auto')
        title = TextBlock('Cisco Webex Teams')
        message = TextBlock('Buttons and Cards Release', size='Large', weight='Bolder', color='Light')
        col0102 = Column(items=[title, message])
        colset01 = ColumnSet(columns=[col0101, col0102])
        # Available Action
        approve = Submit(
            title= 'Approve',
            data= '''{'action':'approve', 'target':'approval link here'}'''
        )
        reject = Submit(
            title= 'Reject',
            data= '''{'action':'reject', 'target':'reject link here'}'''
        )
        portal = OpenUrl(
            url= 'http://www.glocomp.com/',
            title= 'More...'
        )
        card = AdaptiveCard(body=[colset01], actions=[approve, reject, portal])
        message = api.messages.create(room.id,text='approval require', attachments=[card])
        print("New message created, with ID:", message)
        print(message.text)
    except ApiError as e:
        print(e)

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
