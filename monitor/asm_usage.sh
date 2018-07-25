#!/bin/bash

# created by f00378403, 20180725

source ~/.bash_profile

declare -A asm_usage
declare $( asmcmd ls -ls | awk 'BEGIN{quota=0} NR>1{
	if ($2=="EXTERN") {
		quota = 1
	} else if ($2=="NORMAL") {
		quota = 2
	} else if ($2=="HIGH) {
		quota = 3
	}
	print "asm_usage["$13"]="100-int($10*100*quota/$7)}' )

for key in ${!asm_usage[*]}
do
	if [ "$key" = "DATA01/" ]; then
		continue
	fi
	if (( ${asm_usage[$key]} > 80 )); then
		message=${message}"$key up to ${asm_usage[$key]}%\n"
	fi
done

if [ -n $message ]; then
	message="### asm usage on $HOSTNAME ###\n"${message}
	/home/grid/script/bidwsns-bin -tel "18613146197" -msg "`echo -e ${message}`"
fi
