# BanBOT-TelegramAPI-Bot
Boobs are softer with APIs.

#How to make it work:
- edit in bot.sh & update.sh the (relative?) path of the "pipe" log (file.log?) (it is automatically created)
- write the token in token.txt
- run: `chmod +x ./bot.sh`
- run: `chmod +x ./update.sh`
- ...and finally: `./bot.sh` (in tmux?)
- If you were using webHook unregister it by calling API webHook method with no url:
 - `curl -s "https://api.telegram.org/bot${token}/webHook?url="`
 - (Replacing ${token} with your bot token)
- Enjoy.

Note: This bot uses the official APIs.

Note2: I strongly reccommend NOT to run BanBOT as root, so you should really:  `useradd -m -s /bin/bash telegram` or whatev.

Note3: It's a mobile phone produced by Samsung.
