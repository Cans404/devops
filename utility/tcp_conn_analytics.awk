#!/bin/awk -f

# created by Cans, 20170520
# usage: ./tcp_conn_analytics.awk tcp_conn_record.log
# usage: netstat -atpln | grep "30015" | awk -f tcp_conn_analytics.awk

{
	addr = substr($5, 1, index($5, ":") - 1);
	arr[addr]++
}

END{
	for(i in arr){
		printf("%s\t%s\n", i, arr[i]) | "sort -k2 -nr"
	}
}
