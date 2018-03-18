#!/bin/python

# hana_auto_install.py
# created by Cans, 20180313

import os
import sys
import shutil
import os.path
import subprocess

mount_point = ["/usr/sap", "/hana/shared", "/hana/data", "/hana/log", "/nasbk"]
setup_basic = ["hana_cfg_8100.sql", "script", "SAP_HANA_DATABASE"]
dummy_cmd = "dd if=/dev/zero of=/hana/log/dummy_file.dat bs=1M count=204800"

install_cmd = '''./SAP_HANA_DATABASE/hdbinst --batch --sid=HPX --number=XX --system_usage=production \
--password=***@123 --datapath=/hana/data/HPX --logpath=/hana/log/HPX --system_user_password=***@123'''

# 1. mount points check
for dir in mount_point :
	flg = os.path.exists(dir)
	if flg == False :
		print "%s does'nt exist." % dir
		os.exit(1)
print "mount points check passed."

# 2. setup files check
for file in setup_basic :
	flg = os.path.exists(file)
	if flg == False :
		print "%s does'nt exist." % file
		os.exit(1)
print "setup files check passed."

# 3. db info prepare
print "input hana system name(e.g. HP2): ",
sid = sys.stdin.readline().strip('\n')
print "input hana inst number(e.g. 00): ",
inst = sys.stdin.readline().strip('\n')

# 4. create folders
print "\nstart to create path..."
os.mkdir("/hana/data/" + sid)
os.mkdir("/hana/log/" + sid)

dir_cmd1 = "mkdir -p /nasbk/%s/{DataBackup,LogBackup,ConfigBackup}" % sid
dir_cmd2 = "mkdir -p /nasbk/%s/{sampling/{tcp,thread,statement,connection,archive},log}" sid

tmp = subprocess.call(dir_cmd1, shell = True)
tmp = subprocess.call(dir_cmd2, shell = True)

# 5. create dummy file
flg = os.path.exists("/hana/log/dummy_file.dat")
if flg = False :
	print "\nstart to create dummy file..."
	tmp = subprocess.call(dummy_cmd, shell = True)
else:
	print "dummy file already existed."

# 6. install hana
install_cmd = install_cmd.replace("HPX", sid)
install_cmd = install_cmd.replace("XX", inst)

print "\nstart to install hana..."
tmp = subprocess.call(install_cmd, shell = True)

# 7. configure hana
print "\nstart to configure hana..."
cfg_cmd = 'su - %sadm -c "hdbsql -i %s -u system -p ***@123 -I %s"' % (sid.lower(), inst, os.path.abspath(setup_basic[0]))
tmp = subprocess.call(cfg_cmd, shell = True)
key_cmd = 'su - %sadm -c "hdbuserstore set BACKUPKEY %s:3%s15 hanabk ***@123"' % (sid.lower(), os.getenv("HOATNAME"), inst)
tmp = subprocess.call(key_cmd, shell = True)

# 8. scripts deployment
print "\nstart to deploy scripts"
shutil.copytree("./script", "/nasbk/%s/script" % sid)
tmp = subprocess.call("chown -R 1001:79 /nasbk/" + sid, shell = True)

init_env = "/usr/sap/%s/home/.sapenv.sh" % sid
env_var = "script=/nasbk/%s/script; export script"
deploy_cmd = "sed -i '3 a %s' " % env_var + init_env
tmp = subprocess.call(deploy_cmd, shell = True)

# 9. add python lib
print "\nstart to add python lib..."
pyhm_dir = "/usr/sap/%s/HDB%s/exe/Python/" % (sid, inst)
py_dir = pyhm_dir + "lib/python2.7/"
pylib_dir = py_dir + "site-packages"

os.chmod(pyhm_dir, 0o755)
os.chmod(py_dir, 0o755)
os.chmod(pylib_dir, 0o755)

shutil.copytree("./python/hanacli", py_dir + "hanacli")
tmp = subprocess.call("chown -R 1001:79 " + pydir + "hanacli", shell = True)

os.makedirs("/opt/oracle")
shutil.copytree("./python/instantclient_12_1", "/opt/oracle/instantclient_12_1")

init_env = "/usr/sap/%s/home/.bashrc" % sid
env_var = "export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1:$LD_LIBRARY_PATH"
deploy_cmd = "sed -i '$ a %s' " % env_var + init_env
tmp = subprocess.call(deploy_cmd, shell = True)

orcl_bd = 'su - %sadm -c "cd %s/python/cx_Oracle-6.0.3/; python setup.py build"' % (sid_lower(), os.getcwd())
orcl_exe = 'su - %sadm -c "cd %s/python/cx_Oracle-6.0.3/; python setup.py install"' % (sid_lower(), os.getcwd())
ps_exe = 'su - %sadm -c "cd %s/python/psutil-5.4.1/; python setup.py install"' % (sid_lower(), os.getcwd())

tmp = subprocess.call(orcl_bd, shell = True)
tmp = subprocess.call(orcl_exe, shell = True)
tmp = subprocess.call(ps_exe, shell = True)
