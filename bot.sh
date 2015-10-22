#!/usr/bin/env bash

#
#BANBOT IS HERE!
#

bot_token=$(cat token.txt);
log_fifo="hook.log";
#don't edit below!!
export bot_token;

if ! [ -a "$log_fifo" ];
then
	mkfifo "$log_fifo";
fi;

while true; do sleep 999; done > "$log_fifo" &

mlist=(nmap nerdz xkcd torrent);
declare -A Amutex;
for i in "${mlist[@]}";
do
	Amutex[$i]=$(mktemp --suffix ".tbot");
done;
export Amutex;

function clear_mutex {
	for i in "${Amutex[@]}";
	do
		rm "$i";
		echo "[i]Removed mutex $i";
	done;
}

./update.sh 2>/dev/null &
update_pid=$!;

trap 'exit $?' INT TERM
trap 'echo ""; clear_mutex; kill ${update_pid}' EXIT

function get_mutex {
	mutex=$1;
	tmp=$(cat "$mutex");
	if [ "$tmp" = "" ];
	then
		echo "1" >"$mutex";
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
	echo -n "" >"$mutex";
}

function raw_telegram {
	echo "[>]RAW: $*" >&2; #console only
	apiurl="https://api.telegram.org/bot${bot_token}/";
	tmpcurl="";
	x=true;
	for i in "$@";
	do
		i=${i//\'/\'\"\'\"\'}; # ' to '"'"'
		if [ "$x" = "true" ];
		then
			x=false;
			tmpcurl+="curl --retry 10 -s '${apiurl}${i}'";
		else
			tmpcurl+=" -F '${i}'";
		fi;
	done;
	#echo "${tmpcurl}" >&2; #debug
	eval "${tmpcurl}";
}

function send_photo {
	dest="$1";
	file="$2";
	caption="$3";
	raw_telegram "sendPhoto" "chat_id=${dest}" "caption=${caption}" "photo=@${file}";
}

function send_telegram {
	dest=$1;
	message=" $2"; # avoids issues with "^@"
	dpreview=$3;
	if [ "$dpreview" != "true" ];
	then
		dpreview="false";
	fi;
	markdown=$4;
	if [ "$markdown" != "true" ];
	then
		raw_telegram "sendMessage" "chat_id=${dest}" "disable_web_page_preview=${dpreview}" "text=${message}" >/dev/null
	else
		raw_telegram "sendMessage" "chat_id=${dest}" "parse_mode=Markdown" "disable_web_page_preview=${dpreview}" "text=${message}" >/dev/null
	fi;
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

	export GREP_OPTIONS='--color=auto';

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
	#
	sorrymsg="I am terribly sorry, I'll never say words like that again.";
	echo "$message" | grep -iP "(^|[^a-zA-Z])ruby([^a-zA-Z]|$)";
	if [ $? -eq 0 ];
	then
		msgid=$(echo "$packet" | jq -c -r -M ".message.message_id" | sed 's/\n//g');
		raw_telegram "sendMessage" "chat_id=${dest}" "reply_to_message_id=${msgid}" "text=Apologize, now." "reply_markup={\"keyboard\":[[\"${sorrymsg}\"]],\"selective\":true,\"one_time_keyboard\":true}" >/dev/null &
	fi;
	echo "$message" | grep -iP "^${sorrymsg}$";
	if [ $? -eq 0 ];
	then
		msgid=$(echo "$packet" | jq -c -r -M ".message.message_id" | sed 's/\n//g');
		raw_telegram "sendMessage" "chat_id=${dest}" "reply_to_message_id=${msgid}" "text=Good. Don't do that again." "reply_markup={\"hide_keyboard\":true,\"selective\":true}" >/dev/null &
	fi;
	unset sorrymsg;
	#
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
	#COMMANDS & PSEUDO-COMMANDS
	#
	#Commands will work on the L1 thread, without the need of spawning another thread.
	#After the (un)?successful execution of the command, L1 thread will die without running other commands.
	#No L2 threads are created.
	#
	#Pseudo-commands just don't begin with "/"
	#

	#
	#PSEUDO-COMMANDS
	#
	echo "$message" | grep -iP "(www|mobile)\.nerdz\.eu/[a-zA-Z0-9._+-]+[.:][0-9]+";
	if [ $? -eq 0 ];
	then
		tmp=$(get_mutex "${Amutex[nerdz]}");
		if [ "$tmp" = "busy" ];
		then
			send_telegram "$dest" "I'm busy..";
		else
			tmp=$(echo "$message" | grep -ioP "(www|mobile)\.nerdz\.eu/[a-zA-Z0-9._+-]+[.:][0-9]+" | grep -ioP "[a-zA-Z0-9._+-]+[.:][0-9]+");
			if [ "$(which phantomjs)" = "" ];
			then
				echo "[-]PhantomJS not in \$PATH";
			else
				raw_telegram "sendChatAction" "chat_id=$dest" "action=upload_photo";
				tmpf=$(mktemp --suffix ".tbot.png");
				phantomjs screenshot.js "http://www.nerdz.eu/${tmp}" "$tmpf" "postlist" '{"height":-40,"width":10}';
				send_photo "$dest" "$tmpf" | jq -r -M "[.ok]" | grep "false";
				if [ $? -eq 0 ];
				then
					send_telegram "$dest" "Error while retrieving [$tmp](http://www.nerdz.eu/$tmp)" "true" "true";
				fi;
				rm "$tmpf";
			fi;
			release_mutex "${Amutex[nerdz]}";
		fi;
		return;
	fi;
	#
	#FILTER
	#
	echo "$message" | grep -iP "^/.+$";
	if [ $? -ne 0 ];
	then
		#echo -n "$message" | hd; #debug
		echo "No commands.";
		return;
	fi;
	#
	#COMMANDS
	#
	echo "$message" | grep -iP "^/help(@${bot_username})?$";
	if [ $? -eq 0 ];
	then
		tmp="@hBanBOT by @ShotokanZH"$'\n';
		tmp+="_v1.5.0 ...IT'S BANBOT TIME_"$'\n';
		tmp+=$'\n'; #separator
		tmp+="*Usage:*"$'\n';
		tmp+="/help - This."$'\n';
		tmp+="/isnerdzup - Check www.nerdz.eu"$'\n';
		tmp+="/kick id - *Kick user ID from the group*"$'\n';
		tmp+="/ping IP - Ping the IP or hostname"$'\n';
		tmp+="/random - Sarcastic responses"$'\n';
		tmp+="/say words - Say something"$'\n';
		tmp+="/time - Return current GMT+1(+DST) time"$'\n';
		tmp+="/torrent words - Search for VERIFIED torrents"$'\n';
		tmp+="/whoami - Print user infos (no phone)"$'\n';
		tmp+="/whoishere - Print user list (group only)"$'\n';
		tmp+="/xkcd - Random xkcd or specified id"$'\n';
		tmp+=$'\n'; #separator
		tmp+="Note: This bot loves boobs and hates RBUY."$'\n';
		tmp+="Note2: This bot is multithreaded."$'\n';
		tmp+="Note3: This bot knows nerdz."$'\n';
		tmp+="Note4: *Bold* commands require mod||admin level."$'\n';
		tmp+=$'\n'; #separator
		tmp+="This bot is opensource ([github](https://github.com/ShotokanZH/BanBOT-TelegramAPI-Bot/))"$'\n';
		send_telegram "$dest" "$tmp" "true" "true";
		return;
	fi;
	echo "$message" | grep -iP "^/time(@${bot_username})?$";
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "$(date)";
		return;
	fi;
	echo "$message" | grep -iP "^/random(@${bot_username})?$";
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "$(fortune -s)";
		return;
	fi;
	echo "$message" | grep -iP "^/isnerdzup(@${bot_username})?$";
	if [ $? -eq 0 ];
	then
		tmp=$(get_mutex "${Amutex[nmap]}");
		if [ "$tmp" = "busy" ];
		then
			send_telegram "$dest" "I'm busy..";
		else
			raw_telegram "sendChatAction" "chat_id=$dest" "action=typing";
			tmp=$(nmap -p 80 www.nerdz.eu| grep "hosts\? up");
			send_telegram "$dest" "${tmp}";
			release_mutex "${Amutex[nmap]}";
		fi;
		return;
	fi;
	echo "$message" | grep -iP "^/ping(@${bot_username})? (([12]?[0-9]{1,2}\.){3}[12]?[0-9]{1,2}|([a-zA-Z0-9._-]+\.)[a-z-A-Z]{2,11})$";
	if [ $? -eq 0 ];
	then
		ip=$(echo "$message" | grep -ioP "([12]?[0-9]{1,2}\.){3}[12]?[0-9]{1,2}$");
		tmp="";
		if [ "$ip" = "" ];
		then
			if [ "$(which tor-resolve)" = "" ];
			then
				echo "tor-resolve not found in path (tor suite).";
				return;
			else
				domain=$(echo "$message" | grep -ioP "([a-zA-Z0-9._-]+\.)[a-z-A-Z]{2,11}$");
				ip=$(tor-resolve "$domain" 2>/dev/null);
				if [ "$ip" = "" ];
				then
					send_telegram "$dest" "No IP found for $domain" "true";
					return;
				fi;
				newline=$'\n';
				tmp="${domain} => ${ip}${newline}";
			fi;
		fi;
		tmp+="$(ping -c 1 "$ip")";
		send_telegram "$dest" "$tmp" "true";
		return;
	fi;
	echo "$message" | grep -iP "^/ping(@${bot_username})?( |$)";
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "Usage: /ping IP (or hostname)";
		return;
	fi;
	echo "$message" | grep -iP "^/say(@${bot_username})? .*$";
	if [ $? -eq 0 ];
	then
		tmp=$(echo "$message" | grep -ioP "^/say(@${bot_username})? \K.*$");
		send_telegram "$dest" "$tmp";
		return;
	fi;
	echo "$message" | grep -iP "^/whoami(@${bot_username})?$";
	if [ $? -eq 0 ];
	then
		tmp=$(echo "$packet" | jq -M "[.message.from.id,.message.from.first_name,.message.from.last_name,.message.from.username]");
		send_telegram "$dest" "$tmp";
		return;
	fi;
	echo "$message" | grep -iP "^/xkcd(@${bot_username})?( \d+)?$"
	if [ $? -eq 0 ];
	then
		tmp=$(get_mutex "${Amutex[xkcd]}");
		if [ "$tmp" = "busy" ];
		then
			send_telegram "$dest" "I'm busy..";
		else
			raw_telegram "sendChatAction" "chat_id=$dest" "action=upload_photo";
			max=$(curl -s "http://xkcd.com/info.0.json" | jq -c -r -M ".num" | grep -v "null");
			if [ $? -eq 0 ];
			then
				echo -n "[>]Max: ${max} ";
				tmp=$(echo "$message" | grep -ioP "\d+$");
				if [ $? -eq 0 ] && [ "$tmp" -le "$max" ] && [ "$tmp" -ge "1" ];
				then
					id_img=$tmp;
				else
					id_img=$(( 1 + ( RANDOM % ( max - 1 ) ) ));
				fi;
				echo "ComicID: ${id_img}";
				data=$(curl -s "http://xkcd.com/${id_img}/info.0.json" | jq -r -M "[.img,.safe_title,.alt]");
				url=$(echo "$data" | jq -c -r -M ".[0]" | grep -v "^null$");
				if [ $? -eq 0 ];
				then
					tmpf=$(mktemp --suffix ".tbot.png");
					title=$(echo "$data" | jq -r -M ".[1]");
					alt=$(echo "$data" | jq -c -r -M ".[2]");
					curl -s "${url}" > "${tmpf}";
					du -h "${tmpf}";
					send_photo "$dest" "$tmpf" "[${id_img}/${max}] ${title}" | jq -r -M "[.ok]" | grep "false";
					if [ $? -eq 0 ];
					then
						send_telegram "$dest" "Error while retrieving comic #${id_img} image";
					else
						send_telegram "$dest" "<xkcd>${alt}</xkcd>";
					fi;
					rm "$tmpf";
				else
					send_telegram "$dest" "*Error while retrieving comic #${id_img} data*" "true" "true";
				fi;
			else
				send_telegram "$dest" "Error while retrieving max id";
			fi;
			release_mutex "${Amutex[xkcd]}";
		fi;
		return;
	fi;
	echo "$message" | grep -iP "^/torrent(@${bot_username})? [a-zA-Z0-9.,'\" _-]+$";
	if [ $? -eq 0 ];
	then
		tmp=$(get_mutex "${Amutex[torrent]}");
		if [ "$tmp" = "busy" ];
		then
			send_telegram "$dest" "I'm busy..";
		else
			if [ "$(which torify)" = "" ];	#I don't trust you guys.
			then
				echo "[-] torify not found in \$PATH";
			else
				raw_telegram "sendChatAction" "chat_id=$dest" "action=typing";
				searchq=$(echo "$message" | grep -ioP "^/torrent(@${bot_username})? \K.*");
				tmp=$(torify curl --retry 10 -s "https://kat.cr/usearch/${searchq} seeds:1 verified:1/?field=seeders&sorder=desc&rss=1" 2>/dev/null | gunzip);
				BIFS="$IFS";
				IFS=$'\n';
				titles=$(echo "$tmp" | grep -ioP "<torrent:fileName>\K[^<]+" | tr '[(' '<' | tr ')]' '>');
				titles=($titles);
				urls=$(echo "$tmp" | grep -ioP "<enclosure url=\"\K[^\"]+" | tr '[(' '<' | tr ')]' '>');
				urls=($urls);
				seeds=$(echo "$tmp" | grep -ioP "<torrent:seeds>\K[0-9]+");
				seeds=($seeds);
				peers=$(echo "$tmp" | grep -ioP "<torrent:peers>\K[0-9]+");
				peers=($peers);
				IFS="$BIFS";
				x=0;
				tor="";
				min=10;
				if [ "$min" -gt "${#seeds[@]}" ];
				then
					min=${#seeds[@]};
				fi;
				if [ "$min" -eq "0" ];
				then
					tor="*No verified torrents found*"$'\n';
				else
					if [ "$min" -eq "1" ];
					then
						tor="*One torrent found for: '${searchq}'*"$'\n'
					else
						tor="*$min torrents found for: '${searchq}'*"$'\n'
					fi;
					while [ "$x" -lt "$min" ];
					do
						tor+="(${seeds[$x]}:${peers[$x]}) [${titles[$x]}](${urls[$x]})"$'\n';
						x=$(( x + 1 ));
					done;
				fi;
				send_telegram "$dest" "$tor" "true" "true";
			fi;
			release_mutex "${Amutex[torrent]}";
		fi;
		return;
	fi;
	echo "$message" | grep -iP "^/torrent(@${bot_username})?( |$)";
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "Usage: /torrent string";
		return;
	fi;
	#
	#"GOD MODE" commands
	#
	#commands that requires a real user acting as a "bot" via telegram-cli
	#To start it run:
	#tg/bin/telegram-cli -k public.key -R --json -C -P 4567 -D
	#
	echo "$message" | grep -iP "^/whoishere(@${bot_username})?$";
	if [ $? -eq 0 ];
	then
		if [ "$dest" = "$user" ];
		then
			send_telegram "$dest" "*You're not in a group chat*" "true" "true";
		else
			cid=$(echo "$dest" | grep -oP "[0-9]+");
			tmp=$(echo "chat_info chat#${cid}"| nc 127.0.0.1 4567 -q 1 | grep "^{" );
			#echo "$tmp"; #debug
			tmp=$(echo "$tmp" | jq -c -r -M "[.members[].username],[.members[].print_name],[.members[].id]");
			tmp=( $tmp );
			t_users=( $(echo "${tmp[0]}" | jq -M -r ".[]") );
			t_displ=( $(echo "${tmp[1]}" | jq -M -r ".[]") );
			t_id=( $(echo "${tmp[2]}" | jq -M -r ".[]") );
			tor="User list for chat #${cid} :"$'\n\n';
			x=0;
			for i in "${t_id[@]}";
			do
				tor+="$i [at]${t_users[$x]} ${t_displ[$x]}"$'\n';
				x=$(( x  + 1 ));
			done;
			send_telegram "$dest" "$tor";
		fi;
		return;
	fi;
	echo "$message" | grep -iP "^/kick(@${bot_username})? [1-9][0-9]+$";
	if [ $? -eq 0 ];
	then
		if [ "$user" = "$dest" ];
		then
			send_telegram "$dest" "*Not in a group chat.*" "true" "true";
		else
			if [ -f "admin" ];	#id list
			then
				cid=$(echo "$dest" | grep -oP "[0-9]+");
				tokick=$(echo "$message" | grep -ioP "[0-9]+$");
				mod=( $(cat mod admin | grep -v "#") );
				ok="false";
				kick="true";
				for i in "${mod[@]}";
				do
					if [ "$i" = "$user" ];
					then
						ok="true";
					fi;
					if [ "$i" = "$tokick" ];
					then
						kick="false";
					fi;
				done;
				if [ "$ok" = "false" ];
				then
					send_telegram "$dest" "*Not a mod.*" "true" "true";
				else
					cat "admin" | grep -v "#" | grep "^${user}$" >/dev/null;
					if [ $? -eq 0 ];
					then
						echo "[+]Admin";
						kick="true";
					fi;
					if [ "$kick" = "true" ];
					then
						raw_telegram "sendChatAction" "chat_id=$dest" "action=typing";
						echo "chat_del_user chat#${cid} user#${tokick}" | nc 127.0.0.1 4567 -q 1 | grep "SUCCESS";
						if [ $? -ne 0 ];
						then
							send_telegram "$dest" "*Something went wrong..*" "true" "true";
						else
							send_telegram "$dest" "*Pew pew pew.*" "true" "true";
						fi;
					else
						send_telegram "$dest" "*Can't kick an admin.*" "true" "true";
					fi;
				fi;
			else
				send_telegram "$dest" "*No admin found*" "true" "true";
			fi;
		fi;
		return;
	fi;
	echo "$message" | grep -iP "^/kick(@${bot_username})?( |$)";
	if [ $? -eq 0 ];
	then
		send_telegram "$dest" "Usage: /kick userid";
		return;
	fi;
	#echo -n "$message" | hd; #debug
	echo "No commands.";
}

if [ "$(which jq)" = "" ];
then
	echo "No jq command found in \$PATH";
	exit 1;
fi;

bot_self=$(raw_telegram "getMe");
if [ "$(echo "$bot_self" | jq -c -r -M ".ok")" = "false" ];
then
	echo "Something went wrong during 'getMe'..";
	echo "[>]RAW: $bot_self";
	exit 1;
fi;
bot_username=$(echo "$bot_self" | jq -c -r -M ".result.username");
export bot_username;
echo "Bot: @${bot_username}";

while read -r line;
do
	#echo $line; #debug
	packet=$(echo "$line" | jq -c -r -M "[.message.from.username,.message.from.id,.message.chat.id,.message.text]");
	echo "";
	echo "$packet";
	message=$(echo "$packet" | jq -r -M ".[3]" | sed 's/\\n/ /g' | tr "\n" " " | sed -e 's/[[:space:]]*$//');
	echo "Message: $message";
	user=$(echo "$packet" | jq -r -M ".[1]");
	chat=$(echo "$packet" | jq -r -M ".[2]");
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
