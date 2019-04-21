#!/bin/bash

# created by Cans, 20190421
# mysql 5.7.25 installer

# 0. prepare
groupadd mysql
useradd -r -g mysql -s /bin/false mysql

base_dir="/data/service/mysql"
deamon="${base_dir}/support-files/mysql.server"
cnf_file="/etc/my.cnf"
install_log="/tmp/mysql_install.log"
pkg="mysql-5.7.25-linux-glibc2.12-x86_64"

yum -y install libaio numactl* >> $install_log 2>&1
(($? != 0)) && { echo "lib install faied"; exit 1; }

# 1. download
cd /data/service
wget -q http://fileserver/pkg/mysql/${pkg}.tar.gz
wget -q http:/fileserver/pkg/mysql/my-default.cnf -o /etc/my.cnf

# 2. unpack
tar -zxf ${pkg}.tar.gz
mv $pkg mysql

# 3. local
mkdir ${base_dir}/mysql-files
chown mysql:mysql ${base_dir}/mysql-files
chmod 750 ${base_dir}/mysql-files

mkdir /var/run/mysqld
chown mysql:mysql /var/run/mysqld

ln -s /data/userdata/mysql ${base_dir}/data

# 4. config
echo "export PATH=\$PATH:${base_dir}/bin" >> /etc/profile
source /etc/profile

sed -i "/^datadir/ s|/.*$|${base_dir}/data|" $cnf_file
sed -i "/^socket/ s|/.*$|${base_dir}/data/mysql.sock|" $cnf_file

cat << EOF >> $cnf_file
[client]
socket=${base_dir}/data/mysql.sock
 
[mysql]
socket=${base_dir}/data/mysql.sock
EOF

sed -i "/^basedir/ s|=.*$|=${base_dir}|" $deamon
sed -i "/^datadir=/ s|=.*$|=${base_dir}/data|" $deamon
sed -i "/^mysqld_pid/ s|=.*$|=/var/run/mysqld/mysqld.pid|" $deamon

# 5. init
${base_dir}/bin/mysqld --initialize --user=mysql --basedir=$base_dir --datadir=${base_dir}/data >> $install_log 2>&1
${base_dir}/bin/mysql_ssl_rsa_setup >> $install_log 2>&1
grep "ERROR" $install_log > /dev/null && { echo "db init faied"; exit 2; }
chown -R mysql:mysql ${base_dir}/data/*

# 6. start
cp $deamon /etc/init.d/mysqld
service mysqld start >> $install_log 2>&1
(($? != 0)) && { echo "mysql start faied"; exit 3; }

# 7. privilege
tmp_passwd=`awk -F ': ' '/temporary password/ {print $2}' $install_log`

${base_dir}/bin/mysql --connect-expired-password -u root -p${tmp_passwd} >>$install_log 2>&1 <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'xxxxxx';		# modify here
GRANT ALL PRIVILEGES ON *.* TO 'root'@'*.*.*.*' IDENTIFIED BY 'Admin@123' WITH GRANT OPTION;		# modify here
FLUSH PRIVILEGES;
EOF

(($? != 0)) && { echo "privilege set faied"; exit 4; }

# 8. cleaner
rm -f /tmp $install_log /data/service/${pkg}.tar.gz
