#!/bin/bash

# created by Cans, 20181220
# ocr status his analysor

[ ${oops_home} ] && cd ${oops_home} || { echo "oops home not found"; exit 1; }

if [[ $1=="interface" || $1=="handle" || $1=="wyhandle" ]]; then
	svc=$1
else
	echo "wrong service name, try again"
	exit 1
fi

ip=`hostname -I sed 's/[[:blank:]]*//g'`
logFile="log/available_${svc}.log"

# current unavailability checker
function CurUnavailChk {
	statusArr=(`tail -1 ${logFile} | awk -F ': |[][]' '{print $1,$3,$5}'`)

	if [ ${statusArr[0]} = "unavailable" ]; then
		start=`date -d "${statusArr[1]} ${statusArr[2]}" +%s`
		end=`date -d "${statusArr[3]} ${statusArr[4]}" +%s`

		duration=$((end - start))

		echo "retHandler ${ip}:${duration}"
	fi
}

# history unavailability counter for specified day
function HisUnavailCntDly {
	day=$1
	declare -i count=0
	declare -i total=0

	dayStart=`date -d "${day}" +%s`
	dayENd=$((dayStart + 86399))

	while read line; do
		statusArr=(`echo ${line} | awk -F ': |[][]' '{print $1,$3,$5}'`)

		start=`date -d "${statusArr[1]} ${statusArr[2]}" +%s`
		end=`date -d "${statusArr[3]} ${statusArr[4]}" +%s`

		if ((dayStart<=start && end<=dayEnd)); then
			total+=$((end - start))
			count+=1
			continue
		fi

		if ((start<dayStart && dayStart<=end && end<=dayEnd)); then
			total+=$((end - dayStart))
			count+=1
			continue
		fi

		if ((dayStart<=start && start<=dayEnd && end>dayEnd)); then
			total+=$((dayEnd - start))
			count+=1
			break
		fi

		if ((start<dayStart && end>dayEnd)); then
			total+=$((dayEnd - dayStart))
			count+=1
			break
		fi
	done < <(grep "unavailable" ${logFile})

	if ((count > 0)); then
		echo "retHandler ${ip}:${total}:${count}"
	fi
}

# history unavailability counter for specified month
function HisUnavailCntMly {
	mth=$1
	total=`grep "unavailable" ${logFile} | wc -l`
	before=`grep "unavailable" ${logFile} | sed -n "/${mth}/{=;q}"`
	behind=`grep "unavailable" ${logFile} | tac | sed -n "/${mth}/{=;q}"`

	if ((before != 0)); then
		count=$(( total - (before-1) - (behind-1) ))
		echo "retHandler ${ip}:${count}"
	fi
}

# history unavailability counter group by date/month
function HisUnavailCntGroupBy {
	start=$1
	end=$2

	if ((${#1} == 10 && ${#2} == 10)); then
		declare -i startUnix=`date -d "${start}" +%s`
		declare -i endUnix=`date -d "${end}" +%s`

		while ((startUnix <= endUnix)); do
			dtStr=`date -d@"${startUnix}" +%F`
			HisUnavailCntDly ${dtStr} | awk -F ':' -v date=${dtStr} '{print date,$2,$3}'
			startUnix+=86400
		done
	elif ((${#1} == 7 && ${#2} == 7)); then
		declare -i startUnix=`date -d "${start}-01" +%s`
		declare -i endUnix=`date -d "${end}-01" +%s`

		while ((startUnix <= endUnix)); do
			dtStr=`date -d@"{startUnix}" +%Y-%m`
			HisUnavailCntMly ${dtStr} | awk -F ':' -v date=${dtStr} '{print date,$2}'
			startUnix=`date -d "${dtStr}-01 +1 month" +%s`
		done
	fi
}

case ${#} in
	1)
		CurUnavailChk;;
	2)
		if ((${#2} == 10)); then
			HisUnavailCntDly $2
		elif ((${#2} == 7)); then
			HisUnavailCntMly $2
		fi;;
	3)
		HisUnavailCntGroupBy $2 $3;;
esac
