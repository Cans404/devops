#!/bin/bash

# created by Cans, 20181214
# ocr status checker

if [[ ! $@ =~ ^\-.+ ]]; then
	echo "wrong usage, option -h for help"
	exit 1
fi

function interfaceChecker {
	interface=`ps -ef | grep "ocr_interface.yaml" | grep -v "grep" | wc -l`

	if ((${interface}==1)); then
		interfaceStart=`ps -eo lstart,cmd | grep "ocr_interface.yaml" | grep -v "grep" | \
		awk '{sprintf("date -d \"%s\" +\"%%F %%T\"", $2" "$3" "$4" "$5) | getline ifaceStart; print ifaceStart}'`
		echo "ocr interface service is running, uptime: ${interfaceStart}"
	else
		echo "ocr interface service shutted down"
	fi
}

function handleChecker {
	receive=`ps -ef | grep "gpu_${1}ocr_receive.yaml" | grep -v "grep" | wc -l`
	handle=`ps -ef | grep "gpu_${1}ocr_handle.yaml" | grep -v "grep" | wc -l`

	if ((${receive}==1 && ${handle}==8)); then
		maxTm=`ps -eo pid,lstart,etime,cmd | grep -E "gpu_${1}ocr_receive.yaml|gpu_${1}ocr_handle.yaml" | \
		grep -v "grep" | awk 'BEGIN{max=0; tm=""} \
		{startTm=$3" "$4" "$6" "$5; sprintf("date -d \"%s\" +%%s", startTm) | getline unixTm; \
		if(unixTm > max){max=unixTm; tm=startTm}} END{print tm}'`
		handleStart=`date -d ${maxTm} +"%F %T"`
		echo "ocr ${1}handle service is running, uptime: ${handleStart}"
	else
		echo "ocr ${1}handle service shutted down"
	fi
}

while getops ":hn:" options; do
	case ${options} in
		n)
			srcName=${OPTARG};;
		h)
			echo -e "This script is used for getting status of ocr services which include interface, handle, wyhandle.\n"
			echo -e "Usage: ocrStatusChecker.sh [-h-n] [interface|handle|wyhandle]\n"
			echo -e "Option description as below:\n"
			echo "-h: help information"
			echo "-n: specify the service name"
			echo -e "\nExample:\n"
			echo "./ocrStatusChecker.sh -h"
			echo "./ocrStatusChecker.sh -n interface";;
		\?)
			echo "Option -${OPTARG} is illegal! Option -h for help"
			exit 1;;
	esac
done

case ${srcName} in
	handle)
		handleChecker;;
	wyhandle)
		handleChecker "wy";;
	interface)
		interfaceChecker;;
	*)
		echo "Wrong service name, option -h for help";;
esac
