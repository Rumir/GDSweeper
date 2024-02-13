#!/usr/bin/python3

################################
# GDSweeper Twitch Integration #
# AUTHOR    : Rumir            #
# VERSION   : 0.0.1            #
# LAST EDIT : 2024-02-13       #
################################

from twitchAPI.twitch import Twitch
from twitchAPI.oauth import UserAuthenticator
from twitchAPI.type import AuthScope, ChatEvent
from twitchAPI.chat import Chat, EventData, ChatCommand
import asyncio
import socket

### CONFIG #########################
APP_ID = "YOUR_APP_ID"
APP_SECRET = "YOUR_APP_SECRET"
TARGET_CHANNEL = "YOUR_CHANNEL_NAME"
####################################

########################################
# !!! NO EDITING BEYOND THIS POINT !!! #
########################################


### SCRIPT SETTINGS ###################################
###### Don't touch this, unless you know what you do ##
UDP_IP   = "127.0.0.1"
UDP_PORT = 23001
USER_SCOPE = [AuthScope.CHAT_READ, AuthScope.CHAT_EDIT]
#######################################################
async def sweep_command(cmd: ChatCommand):
    if len(cmd.parameter) == 0:
        await cmd.reply("[SWEEP] Befehl: !sweep ZAHL   (von 1 bis 100)")
    else:
        tInt = ""
        try:
            tInt = int(cmd.parameter)
        except ValueError:
            await cmd.reply("[SWEEP] Das war keine gültige Zahl! (von 1 bis 100)")
            return

        if tInt == "":
            await cmd.reply("[SWEEP] Fehler.")
            print("ERROR while casting string to int")
            return

        if tInt <= 0:
            await cmd.reply("[SWEEP] Die Zahl war zu klein! (von 1 bis 100)")
            return

        elif tInt > 100:
            await cmd.reply("[SWEEP] Die Zahl war zu groß! (von 1 bis 100)")
            return

        else:
            vInt = tInt - 1
            msgToSend = "COMMAND_CLICK_{}".format(str(vInt))
            resp = await sendMessageToGame(msgToSend)
            respText = resp.decode("utf-8")

            if respText == "RESPONSE_GOOD":
                await cmd.reply(
                        "[SWEEP] {} hat ein Feld aufgedeckt und ist nicht explodiert.".format(
                            cmd.user.name)
                        )
            elif respText == "RESPONSE_WINNER":
                await cmd.reply(
                        "[SWEEP] {} hat das letzte Feld aufgedeckt. Glückwunsch!".format(
                            cmd.user.name)
                        )
            elif respText == "RESPONSE_GAMEOVER":
                await cmd.reply(
                        "[SWEEP] KA-BOOM! {} hat eine Mine ausgelöst!".format(
                            cmd.user.name)
                        )
            elif respText == "RESPONSE_INVALID":
                await cmd.reply(
                        "[SWEEP] {}, dieses Feld ist bereits aufgedeckt.".format(
                            cmd.user.name)
                        )
            else:
                await cmd.reply("[SWEEP] Unexpected Error!")
                print("""ERROR while handling response text:
User:      {}
Parameter: {}
Response:  {}""".format(cmd.user.name, cmd.parameter, respText)
                      )


async def sendMessageToGame(message: str):
    pSock = socket.socket(socket.AF_INET,
                          socket.SOCK_DGRAM)
    pSock.sendto(message.encode(), (UDP_IP, UDP_PORT))
    return pSock.recv(1024)


async def on_ready(ready_event: EventData):
    print("RumirSanBot has started, Ready to Rumble")
    print("Joining channel...")
    await ready_event.chat.join_room(TARGET_CHANNEL)
    print("Joined channel.")


async def run():
    global twitch, auth
    twitch = await Twitch(APP_ID, APP_SECRET)
    auth = UserAuthenticator(twitch, USER_SCOPE, url="https://127.0.0.1:17563")
    token, refresh_token = await auth.authenticate()
    await twitch.set_user_authentication(token, USER_SCOPE, refresh_token)
    print("4")

    chat = await Chat(twitch)

    print("5")
    chat.register_event(ChatEvent.READY, on_ready)

    chat.register_command('sweep', sweep_command)

    chat.start()

    try:
        input("Press ENTER to Stop\n")
    finally:
        chat.stop()
        await twitch.close()

asyncio.run(run())

