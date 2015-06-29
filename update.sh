#!/usr/bin/env bash
token=$(cat token.txt);
timeout=60;
log="hook.log"
#don't edit below!!
update_url="https://api.telegram.org/bot${token}/getUpdates?timeout=${timeout}&offset=";
offset=0;

while true;
do
	data=$(curl -s "${update_url}${offset}");
	if [ $? -eq 0 ];
	then
		ok=$(echo "${data}" | jq -c -r -M ".ok");
		if [ "$ok" = "true" ];
		then
			x=0;
			echo "${data}" | jq -c -r -M ".result" | grep -vP "^\[\]$" >/dev/null;
			if [ $? -eq 0 ];
			then
				tmp=true;
				while [ "$tmp" != "null" ];
				do
					tmp=$(echo "${data}" | jq -c -r -M ".result[${x}]");
					x=$(( x + 1 ));
					if [ "$tmp" != "null" ];
					then
						offset=$(echo "${tmp}" | jq -c -r -M ".update_id");
						offset=$(( offset + 1 ));
						echo "$tmp" >> "$log";
					fi;
				done;
			fi;
		fi;
	fi;
done;
