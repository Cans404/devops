#!/bin/bash

# created by cans, 20170122

[ $script ] && cd $script || { echo "home not found"; exit 1; }

message="./message/resource_report.tmp"
read tel_ls mail_ls <<< `awk -F ':' 'BEGIN{ORS=" "}{print $2}' ./config/contacts.cfg`
declare -A rs_quota
rs_quota=([mem]=80 [cpu_idle]=20 [cpu_wait]=20 [cpu_load]=80 [disk]=80)

function mem_usage {
	cat /proc/meminfo | awk -v qt=${rs_quota[mem]} -F ":|[ ]*" '
	$1~/^(MemTotal|MemFree|Buffers|Cached|SReclaimable)/{
		if ($1=="MemTotal")
			total=$3
		else
			free+=$3
	}
	END{
		usage=int((total-free)*100/total)
		if (usage>=qt)
			printf("ram is up to %s%%.\n", usage)
	}'
} >> $message

function disk_usage {
	df -hP | awk -v qt=${rs_quota[disk]} '$6~/^\//{
		if ( substr($5,1,length($5)-1) - qt > 0 )
			arr[$6]=$5
	}
	END{
		for (x in arr)
		printf("%s is up to %s.\n", x, arr[x])
	}'
} >> $message

function cpu_usage {
	cores=`cat /proc/cpuinfo | grep "processor" | sort -u | wc -l`
	load=`cat /proc/loadavg | awk '{print $1}'`; load=${load%.*}
	eval `cat /proc/stat | awk '/\<cpu\>/{printf("total1=%s; idle1=%s; wait1=%s", $2+$3+$4+$5+$6+$7+$8, $5, $6)}'`
	sleep 5
	eval `cat /proc/stat | awk '/\<cpu\>/{printf("total2=%s; idle2=%s; wait2=%s", $2+$3+$4+$5+$6+$7+$8, $5, $6)}'`

	declare -A ratio
	ratio[load]=`echo "scale = 0; $load * 100 / $cores" | bc`
	ratio[idle]=`echo "scale = 0; ($idle2 - $idle1) * 100 / ($total2 - $total1)" | bc`
	ratio[wait]=`echo "scale = 0; ($wait2 - $wait1) * 100 / ($total2 - $total1)" | bc`

	for i in ${!ratio[@]}
	do
		case $i in
			"load" ) ((${ratio[$i]} >= ${rs_quota[cpu_load]})) && echo "cpu load is up to $load, ${ratio[$i]}%.";;
			"idle" ) ((${ratio[$i]} < ${rs_quota[cpu_idle]})) && echo "cpu idle is lower than ${ratio[$i]}%.";;
			"wait" ) ((${ratio[$i]} >= ${rs_quota[cpu_wait]})) && echo "cpu wait is up to ${ratio[$i]}%.";;
		esac
	done
} >> $message

# main start here
alert_flag="False"

if [[ `date +%M` == 30 ]]; then
	disk_usage
fi

disk_usage
mem_usage; cpu_usage

content_count=`cat $message | wc -l` && (($content_count >= 1)) && alert_flag="True"

if [ $alert_flag = "True" ]; then
	sed -i "1 i ## usage alert on `hostname`\! ##" $message

	mail -r "os-monitor@`hostname`" -s "### os resource usage alert! ###" "${mail_ls}"< $message
fi

cat /dev/null > $message
