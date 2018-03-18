#!/bin/bash

# created by Cans, 20161213
# file size group by date
# usage: ./size_group_by.sh or ./size_group_by.sh /home/Cans

cd ${1-.}
date_arr=(`ls -l | grep -v "total" | awk '{printf("%s_%s\n", $6, $7)}' | sort | uniq`) 

for x in ${date_arr[*]}
do
	echo -e -n "$x\t\t"
	du -hsc `ls -l | awk -v var="$x" '{if(var == $6"_"$7) print $9}'` | grep "total" | cut -d \t -f1
done
