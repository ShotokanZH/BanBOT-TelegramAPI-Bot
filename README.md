# BanBOT-TelegramAPI-Bot
Boobs are softer with APIs.

#How to make it work:
- move hook.php to a webserver (https)
- edit in bot.sh & hook.php the (relative?) path of the "pipe" log (file.log?) (it is automatically created)
- add in bot.sh the token (bot_token variable)
- run: `chmod +x ./bot.sh`
- ...and finally: `./bot.sh` (in tmux?)
- Enjoy.

Note: This bot uses the official APIs.

Note2: I strongly reccommend NOT to run BanBOT as root, so you should really:  `useradd -m -s /bin/bash telegram` or whatev.

Note3: It's a mobile phone produced by Samsung.
