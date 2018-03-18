# hfm_reboot_mly.py
# Created by Cans, 2017-09-05
# Hyperion HFM maintenance during reboot monthly

import os
import shutil
import glob
import time
import datetime
import subprocess

cur_dt = datetime.date.today()
two_mth_ago = cur_dt + datetime.timedelta(days = -60)

hfm_log = "D:\\Oracle\\Middleware\HFM11_projects\\HFM11_1\\diagnostics\\logs\\hfm"
iis_log = "C:\\inetpub\\logs\\LogFiles\\W3SVC1"
bk_dir = ["D:\\LOGBACKUP\\%s\\%s" % (i, cur_dt) for i in ("hfm", "iis")]
os.makedirs(bk_dir[0], 0o755)
os.makedirs(bk_dir[1], 0o755)

# stop hfm services
cmd_stop = hfm_log + "\\..\\..\\..\\bin\stop.bat"
cmd_kill = 'TASKKILL /F /FI "USERNAME eq hfmadmin"'
rt_code = subprocess.call(cmd_stop, shell = True)
rt_code = subprocess.call(cmd_kill, shell = True)

time.sleep(5)

# move hfm logs
os.chdir(hfm_log)

for f in ["hfm.odl.log", "HsvEventLog.log"]:
	shutil.move(f, bk_dir[0])

# move iis logs of two months ago
os.chdir(iis_log)
i = 0

for f in glob.glob("*.log"):
	mtime = os.path.getmtime(f)

	if datetime.date.fromtimestamp(mtime) < two_mth_ago:
		shutil.move(f, bk_dir[1])
		i += i

# summary
print "%d log(s) archived on %s." % (i + 2, os.getenv("computername"))
