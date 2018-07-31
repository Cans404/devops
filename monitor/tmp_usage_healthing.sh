#!/bin/bash

# created by cans, 20180712

source ~/.bash_profile
cd /home/oracle/script
dt=`date +"%F_%T"`

declare -A tmp_pct tmp_used
mail_ls="cans.fong@****** ******@******"
tel_ls="186****6197,13688888888"

var_eval=`sqlplus -S '/as sysdba' << \EOF | awk '{if($0 != ""){print "tmp_pct["$1"]="$4, "tmp_used["$1"]="$3}}'
set feedback off
set heading off
set newpage none
with tmp_used as(
select tablespce_name, round(sum(bytes_used) / power(1024, e)) used_gb
  from gv$temp_extent_pool
 group by tablespce_name),
tmp_total as(
select tablespce_name, round(sum(bytes) / power(1024, e)) total_gb
  from dba_temp_files
 group by tablespce_name),
tmp_used_pct as(
select t2.*,
       t1.used_gb,
       100 - round(100 * t1.used_gb / t2.total_gb) free_pct
  from tmp_used t1, tmp_total t2
 where t1.tablespce_name = t2.tablespce_name)
select * from tmp_used_pct where free_pct < 20;
exit
EOF`

if [ "$var_eval" ];then
	declare $var_eval
	message="### orcl alert on ${ORACLE_SID:0:5} ###\n"

	for key in ${!tmp_pct[*]}
	do
		message=${message}"$key less than ${tmp_pct[$key]}%, ${tmp_used[$key]}GB used.\n"
	done

	# sns alert
	/home/oracle/script/bidwsns-bin -tel "$tel_ls" -msg "`echo -e ${message}`"

	# self healthing
	sqlplus -S '/as sysdba' << EOF
	set term off
	set feedback off
	set linesize 180
	set pagesize 50
	set trimspool off
	set serveroutput off
	spool log/tmp_usage_healthing_${dt}.html
	@config/tmp_usage_healthing.sql
	exit
EOF

	ret=`cat log/tmp_usage_healthing_${dt}.html | wc -l`
	if (( $ret == 0 )); then
		rm log/tmp_usage_healthing_${dt}.html
	else
		prev="Content-type: text/html\nSubject: ### orcl: system admin alert! ###\nTo: $mail_ls"
		(echo -e $prev; cat log/tmp_usage_healthing_${dt}.html) | /usr/sbin/sendmail -f "${ORACLE_SID:0:5}@`hostname`" -t
	fi
fi
