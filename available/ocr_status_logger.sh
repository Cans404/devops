#!/bin/bash

# created by Cans, 20181217
# ocr status logger

[ ${oops_home} ] && cd ${oops_home} || { echo "oops home not found"; exit 1; }

if [[ $1=="interface" || $1=="handle" || $1=="wyhandle" ]]; then
	svc=$1
else
	echo "wrong service name, try again"
	exit 1
fi

function logUpdate {
	if [ ! -e ${logFile} ]; then
		echo "$1: [${2}] ~ [${3}]" > ${logFile}
	else
		statusArr=(`tail -1 ${logFile} | awk -F ': |[][]' '{print $1,$3,$5}'`)

		if [ $1 = ${statusArr[0]} ]; then
			sed -i '$ d' ${logFile}
			echo "${1}: [${statusArr[1]} ${statusArr[2]}] ~ [${3}]" >> ${logFile}
		else
			if [ $1 = "available" ]; then
				sed -i '$ d' ${logFile}
				echo "${statusArr[0]}: [${statusArr[1]} ${statusArr[2]}] ~ [${2}]" >> ${logFile}
				echo "${1}: [${2}] ~ [${3}]" >> ${logFile}
			else
				echo "${1}: [${statusArr[3]} ${statusArr[4]}] ~ [${3}]" >> ${logFile}
			fi
		fi
	fi
}

retArr=(`./ocr_status_checker.sh -n ${svc} | awk -F ": |, | " '{print $5,$7,$8}'`)
now=`date +"%F %T"`
status=${retArr[0]}
logFile="log/available_${svc}.log"

case ${status} in
	"running")
		logUpdate "available" "${retArr[1]} ${retArr[2]}" "${now}";;
	"down")
		logUpdate "unavailable" "${now}" "${now}";;
	*)
		echo "provide a existing service on this host: interface|handle|wyhandle";;
esac
