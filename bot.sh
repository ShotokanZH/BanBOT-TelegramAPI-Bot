#!/usr/bin/env bash

#
#BANBOT IS HERE!
#

bot_token=""; #put your token here
log_fifo="hook.log";
#don't edit below!!
export bot_token;

if ! [ -a "$log_fifo" ];
then
	mkfifo "$log_fifo";
fi;

mlist=(nmap nerdz);
declare -A Amutex;
for i in ${mlist[@]};
do
	Amutex[$i]=$(mktemp --suffix ".tbot");
done;
export Amutex;

function clear_mutex {
	for i in ${Amutex[@]};
	do
		rm "$i";
		echo "[i]Removed mutex $i";
	done;
}

trap "exit $?" INT TERM
trap "echo ''; clear_mutex" EXIT

function get_mutex {
	mutex=$1;
	tmp=$(cat $mutex);
	if [ "$tmp" = "" ];
	then
		echo "1" >$mutex;
		echo "[i]Created mutex $mutex" >&2;
		echo "free";
	else
		echo "[!]Mutex $mutex is busy" >&2;
		echo "busy";
	fi;
}

function release_mutex {
	mutex=$1;
	echo "[i]Releasing mutex $mutex";
	echo -n "" >$mutex;
}

function raw_telegram {
	func="$1";
	packet="$2";
	echo "[>]RAW: $func$packet" >&2; #console only
	apiurl="https://api.telegram.org/bot${bot_token}/";
	curl -G -s "$apiurl$func" --data-urlencode "$packet";
}

function send_photo {
	dest="$1";
	file="$2";
	apiurl="https://api.telegram.org/bot${bot_token}/";
	echo "[>+]RAW sendPhoto?chat_id=${dest} (@${file})" >&2;
	curl -s "${apiurl}sendPhoto?chat_id=${dest}&photo" -F photo=@${file};
}

function send_telegram {
	dest=$1;
	message=$2;
	raw_telegram "sendMessage?chat_id=$dest&" "text=$message" >/dev/null
}

function bot {
	dest="$1";
	message="$2";

	if [ "$3" = "" ];
	then
		user=$dest;
	else
		user=$3;
	fi;

	packet=$4;

	export GREP_OPTIONS='--color=always';

	echo "$message" | grep -iP "(^|[^a-zA-Z])tette([^a-zA-Z]|$)" ;
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "Le tette sono morbide." &
	fi;
	echo "$message" | grep -iP "(^|[^a-zA-Z])boobs([^a-zA-Z]|$)" ;
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "Boobs are soft." &
	fi;
	echo "$message" | grep -iP "(^|[^a-zA-Z])ruby([^a-zA-Z]|$)";
	if [ $? -eq 0 ];
	then
		msgid=$(echo "$packet" | jq -c -r -M ".message.message_id" | sed 's/\n//g');
		raw_telegram "sendMessage?chat_id=${dest}&reply_to_message_id=${msgid}&text=Apologize,%20now." "reply_markup={\"keyboard\":[[\"I am terribly sorry, I'll never say words like that again.\"]],\"selective\":true,\"one_time_keyboard\":true}"&
	fi;
	echo "$message" | grep -i "say my name";
	if [ $? -eq 0 ];
	then
		tmp=("https://youtu.be/WzhW20hLp6M" "https://youtu.be/uty2zd7qizA" "https://youtu.be/BvZgzDiBFYQ" "Mr.White?" "https://youtu.be/sMbA-ZfYvh8");
		max=${#tmp[@]};
		rand_n=$(( RANDOM % max ));
		send_telegram "$dest" "${tmp[$rand_n]} ($(( rand_n + 1 ))/${max})" &
	fi;
	echo "$message" | grep -i "shrek is love";
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "Shrek is life." &
	fi;
	#
	#COMMANDS
	#
	#Commands will work on the L1 thread, without the need of spawning another thread.
	#After the (un)?successful execution of the command, L1 thread will die without running other commands.
	#No L2 threads are created.
	#
	echo "$message" | grep -i "^/help$";
	if [ $? -eq 0 ];
	then
		tmp="@BanBOT by @ShotokanZH\n";
		tmp+="v1.3 bot api!!\n\n";
		tmp+="Usage:\n";
		tmp+="/help - This.\n";
		tmp+="/time - Return current GMT+1(+DST) time\n";
		tmp+="/random - Sarcastic responses\n";
		tmp+="/isnerdzup - Checks www.nerdz.eu\n";
		tmp+="/ping IP - Pings the IP\n";
		tmp+="/whoami - print user's infos (no phone)\n";
		tmp+="\n"; #separator
		tmp+="Note: This bot loves boobs and hates RBUY.\n";
		tmp+="Note2: This bot is multithreaded.\n";
		tmp+="Note3: This bot knows nerdz.\n";
		tmp=$(echo -e "${tmp}");
		send_telegram "$dest" "${tmp}";
		break;
	fi;
	echo "$message" | grep -i "^/time$";
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "$(date)";
		break;
	fi;
	echo "$message" | grep -i "^/random$";
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "$(fortune -s)";
		break;
	fi;
	echo "$message" | grep -i "^/isnerdzup$";
	if [ $? -eq 0 ];
	then
		tmp=$(get_mutex ${Amutex[nmap]});
		if [ "$tmp" = "busy" ];
		then
			send_telegram "$dest" "I'm busy..";
		else
			tmp=$(nmap -p 820 www.nerdz.eu| grep --color=never "hosts\? up");
			send_telegram "$dest" "${tmp}";
			release_mutex ${Amutex[nmap]};
		fi;
		break;
	fi;
	echo "$message" | grep -iP "^/ping ([12]?[0-9]{1,2}\.){3}[12]?[0-9]{1,2}$";
	if [ $? -eq 0 ];
	then
		ip=$(echo "$message" | grep --color=never -ioP "^/ping \K([12]?[0-9]{1,2}\.){3}[12]?[0-9]{1,2}$");
		tmp=$(ping -c 1 $ip);
		send_telegram "$dest" "$tmp";
		break;
	fi;
	echo "$message" | grep -iP "^/ping( |$)";
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "Usage: /ping IP (no hostname)";
		break;
	fi;
	echo "$message" | grep -i "^/whoami$";
	if [ $? -eq 0 ];
	then
		tmp=$(echo "$packet" | jq -M "[.message.from.id,.message.from.first_name,.message.from.last_name,.message.from.username]");
		send_telegram "$dest" "$tmp";
		break;
	fi;
	echo "$message" | grep -iP "(www|mobile)\.nerdz\.eu/[a-zA-Z0-9._+-]+[.:][0-9]+";
	if [ $? -eq 0 ];
	then
		tmp=$(get_mutex ${Amutex[nerdz]});
		if [ "$tmp" = "busy" ];
		then
			send_telegram "$dest" "I'm busy..";
		else
			tmp=$(echo "$message" | grep --color=never -ioP "(www|mobile)\.nerdz\.eu/[a-zA-Z0-9._+-]+[.:][0-9]+" | grep --color=never -ioP "[a-zA-Z0-9._+-]+[.:][0-9]+");
			if [ "$(which phantomjs)" = "" ];
			then
				echo "[-]PhantomJS not in \$PATH";
			else
				send_telegram "$dest" "Loading nerdz.eu/${tmp} ...";
				tmpf=$(mktemp --suffix ".tbot.png");
				phantomjs screenshot.js "http://www.nerdz.eu/${tmp}" "$tmpf" "postlist" '{"height":-40,"width":10}';
				send_photo "$dest" "$tmpf" | jq -r -M "[.ok]" | grep "false";
				if [ $? -eq 0 ];
				then
					send_telegram "$dest" "Error while retrieving $tmp";
				fi;
				rm $tmpf;
			fi;
			release_mutex ${Amutex[nerdz]};
		fi;
		break;
	fi;
	#echo -n "$message" | hd; #debug
	echo "No commands.";
}

if [ "$(which jq)" = "" ];
then
	echo "No jq command found in \$PATH";
	exit 1;
fi;

while true; do sleep 999; done > "$log_fifo" & #keeps the log file open

while read -r line;
do
	#echo $line; #debug
	packet=$(echo "$line" | jq -c -r -M "[.message.from.id,.message.chat.id,.message.text]");
	echo "";
	echo $packet;
	message=$(echo $packet | jq -r -M ".[2]" | sed 's/\\n/ /g' | tr "\n" " " | sed -e 's/[[:space:]]*$//');
	echo "Message: $message";
	user=$(echo $packet | jq -r -M ".[0]");
	chat=$(echo $packet | jq -r -M ".[1]");
	echo -n "User: $user";
	if [ "$user" = "$chat" ];
	then
		#message in chat
		echo "";
	else
		#message in groupchat
		echo " Chat: $chat";
	fi;
	#L0 spawns L1 thread
	bot "$chat" "$message" "$user" "$line"&
done < "$log_fifo";