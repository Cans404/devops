#!/usr/bin/env python

# os_metric_collecor.py
# created by Cans, 20171122

import os
import time
import signal
import psutil
import cx_Oracle
from hanacli import dbapi

ram_usage_sql = r'''select cast(round(100*(instance_total_memory_used_size/allocation_limit)) as varchar) usage_ratio
from m_host_resource_utilization'''

host = os.getenv("HOSTNAME")
db_sid = os.getenv("SAPSYSTEMNAME")

# creating long connections
# more secure way need for orcl conn
hana_conn = dbapi.connect(userkey="BACKUPKEY")
hana_cur = hana_conn.cursor()
orcl_conn = cx_Oracle.connect("sap***", "test***", "dggm8fu***:1521/***srv")
orcl_cur = orcl_conn.cursor()

def usage_metric_insert(p_type, p_type_detl, p_value, p_batch):
	metrics = {"sid":db_sid, "host":host, "type":p_type, "type_detail":p_type_detl, "value":p_value, "batch":p_batch}
	insert_stmt = "insert into sys_workload values (metric_seq.nextval, :sid, :host, :type, :type_detl, :value, sysdate, :batch)"
	tmp = orcl_cur.execute(insert_stmt, metrics)
	orcl_conn.commit()

def hana_metric_collec(p_batch):
	try:
		tmp = hana_cur.execute(ram_usage_sql)
		ram_usage = hana_cur.fetchone()
	except dbapi.Error as err:
		print err
	else:
		usage_metric_insert("memory", "", ram_usage[0], p_batch)

def os_metric_collect(p_batch):
	# mem_usage_pct = int(psutil.virtual_memory()[2] + 0.5)

	cpu_time = psutil.cpu_times_percent(interval = 10)
	cpu_idle_pct = int(cpu_time[3] + 0.5)
	cpu_wait_pct = int(cpu_time[4] + 0.5)
	cpu_loads = open("/proc/loadavg", 'r').read().split()
	cpu_load = int(float(cpu_loads[0]) + 0.5)
	cpu_load_pct = cpu_load * 100 / psutil.cpu_count()

	net_io1 = psutil.net_io_counters(pernic = True)["bond0"]       # modify here on demand
	time.sleep(1)
	net_io2 = psutil.net_io_counters(pernic = True)["bond0"]
	io_out = (net_io2[0] - net_io1[0]) / 1024
	io_in = (net_io2[1] - net_io1[1]) / 1024

	disk_io1 = psutil.disk_io_counters()
	time.sleep(1)
	disk_io2 = psutil.disk_io_counters()
	io_read = (disk_io2[2] - disk_io1[2]) / 1024
	io_write = (disk_io2[3] - disk_io1[3]) / 1024

	usage_metric_insert("cpu", "idle", cpu_idle_pct, p_batch)
	usage_metric_insert("cpu", "wait", cpu_wait_pct, p_batch)
	usage_metric_insert("cpu", "load", cpu_load_pct, p_batch)
	usage_metric_insert("io", "net_rx", io_in, p_batch)
	usage_metric_insert("io", "net_tx", io_out, p_batch)
	usage_metric_insert("io", "disk_read", io_read, p_batch)
	usage_metric_insert("io", "disk_write", io_write, p_batch)

def disk_size_collect(p_batch):
	disks = ["/hana/data", "/hana/log", "/hana/shared", "/usr/sap"]      # modify here on demand
	for ds in disks:
		disk_usage = psutil.disk_usage(ds).percent
		disk_usage_pct = int(disk_usage + 0.5)
		usage_metric_insert("disk", ds, disk_usage_pct, p_batch)

if __name__ == '__main__':

	def quit(signum, frame):
		print("received os signal: ", signum)
		global exit_signal
		exit_signal = 'Y'

	exit_signal = 'N'
	signal.signal(signal.SIGTERM, quit)

	while True:
		batch_id = int(time.time())
		curt_mins = time.localtime(time.time()).tm_min

		hana_metric_collec(batch_id)
		os_metric_collect(batch_id)
		# disk metrics collect every 30 mins
		if curt_mins % 30 == 0 :
			disk_size_collect(batch_id)

		left = 60 - time.localtime(time.time()).tm_sec
		time.sleep(left)

		if exit_signal == 'Y' :
			orcl_cur.close()
			hana_cur.close()
			orcl_conn.close()
			hana_conn.close()
			break
