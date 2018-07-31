#!/bin/bash

# created by cans, 20180726

source ~/.bash_profile
cd /home/oracle/script

declare -A tmp_wait

function add_tmpfile {
	sqlplus -S '/as sysdba' << EOF
	set newpage none
	set feedback off
	set echo off
	alter tablespace $1 add tempfile '+DATA01' size 32868M autoextend off;
	alter tablespace $1 add tempfile '+DATA01' size 32868M autoextend off;
EOF
}

var_eval=`sqlplus -S '/as sysdba' << \EOF | awk '{if($0 != ""){print "tmp_wait["$1"]="$2}}'
set feedback off
set heading off
set newpage none
select t2.name, count(t1.event) num
   from gv$session t1, sys.ts$ t2, dba_tablespaces t3
where t1.event = 'enq: TS - contention'
  and t1.p2 = t2.ts#
  and t2.name = t3.tablespace_name
  and t3.contents = 'TEMPORARY'
group by t2.name
having count(t1.event) > 50;
exit
EOF`

if [ "$var_eval" ]; then
	declare $var_eval

	if (( ${#tmp_wait[*]} > 0 )); then
		message="### orcl alert on ${ORACLE_SID:0:5} ###\n"

		for key in ${!tmp_wait[*]}
		do
			message=${message}"wait event for $key up to ${tmp_wait[$key]}\n"
			add_tmpfile $key
		done

		/home/oracle/script/bidwsns-bin -tel "186****6197" -msg "`echo -e ${message}`"
	fi
fi
