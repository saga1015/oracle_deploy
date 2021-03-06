#


cd `dirname $0`
if  [ ! -f ./rac_cfg_extend ] ;then
    echo "rac.cfg is not exist"
    exit 1
fi	


source ./rac_cfg_extend
source ./logging.sh
#sysconfig

backup_file(){
    [  -f /etc/security/limits.conf.bak ] ||  cp -rf /etc/security/limits.conf{,.bak}
    [  -f /etc/pam.d/login.bak ] ||  cp -rf /etc/pam.d/login{,.bak}
    [  -f /etc/sysctl.conf.bak ] ||  cp -rf /etc/sysctl.conf{,.bak}
    [  -f /etc/hosts.bak ] ||  cp -rf /etc/hosts{,.bak}
    [  -f /etc/profile.bak ] || cp -rf /etc/profile{,.bak}
    [  -f /lib/udev/rules.d/50-udev-default.rules.bak ] || cp -rf /lib/udev/rules.d/50-udev-default.rules{,.bak}
    [  -f /etc/HOSTNAME.bak ] ||  cp -rf /etc/HOSTNAME{,.bak}
    [  -f /etc/sysconfig/network.bak ] ||  cp -rf /etc/sysconfig/network{,.bak}
}

restore_file(){
    [  -f /etc/security/limits.conf.bak ] &&  cp -rf /etc/security/limits.conf{.bak,}
    [  -f /etc/pam.d/login.bak ] &&  cp -rf /etc/pam.d/login{.bak,}
    [  -f /etc/sysctl.conf.bak ] &&  cp -rf /etc/sysctl.conf{.bak,}
    [  -f /etc/hosts.bak ] &&  cp -rf /etc/hosts{.bak,}
    [  -f /etc/profile.bak ] && cp -rf /etc/profile{.bak,}
    [  -f /lib/udev/rules.d/50-udev-default.rules.bak ] && cp -rf /lib/udev/rules.d/50-udev-default.rules{.bak,}
    [  -f /etc/HOSTNAME.bak ] &&  cp -rf /etc/HOSTNAME{.bak,}
    [  -f /etc/sysconfig/network.bak ] &&  cp -rf /etc/sysconfig/network{.bak,}
}
set_rpm(){
rpm -ivh ../rpm/libcap1-1.10-6.10.x86_64.rpm
rpm -e orarun-1.9-172.20.21.54

}
disable_ntp(){
/etc/init.d/ntpd stop
/etc/init.d/ntp stop 
chkconfig ntpd off  
chkconfig ntp off  
mv /etc/ntp.conf /etc/ntp.org
}
turn_off_firewall(){
    [ -f /etc/init.d/SuSEfirewall2_setup ] && rcSuSEfirewall2 stop
    chkconfig SuSEfirewall2_setup off 
    [ -f /etc/init.d/iptables ] && service iptables stop
    chkconfig iptables off
}
set_env(){
ora_log "check rpm"
set_rpm >/dev/null 2>&1
ora_log "check rpm finish"

cat >> /etc/profile <<EOF
if [ \$USER = "oracle" ] || [ \$USER = "grid" ]; then
        if [ \$SHELL = "/bin/ksh" ]; then
              ulimit -u 16384
              ulimit -n 65536
        else
              ulimit -u 16384 -n 65536
        fi
        umask 022
fi
EOF


cat >> /etc/security/limits.conf <<EOF
grid soft nproc 2047 
grid hard nproc 16384 
grid soft nofile 1024 
grid hard nofile 65536 
oracle soft nproc 2047 
oracle hard nproc 16384 
oracle soft nofile 1024 
oracle hard nofile 65536
EOF

#cat >>/etc/pam.d/login <<EOF
#session required pam_limits.so
#EOF
ora_log "setup sysctl paremeter"
shmmax=`cat /proc/meminfo  | grep MemTotal | awk '{print $2*512}' `
sed -i '/kernel.shmmax/d' /etc/sysctl.conf
cat >>/etc/sysctl.conf <<EOF
kernel.shmmax = $shmmax
fs.aio-max-nr = 1048576 
fs.file-max = 6815744 
kernel.shmmni = 4096 
kernel.sem = 250 32000 100 128 
net.ipv4.ip_local_port_range = 9000 65500 
net.core.rmem_default = 262144 
net.core.rmem_max = 4194304 
net.core.wmem_default = 262144 
net.core.wmem_max = 1048586
EOF
sysctl -p >/dev/null 2>&1 
ora_log "setup sysctl paremeter finish"
#stop ntp
ora_log "disable ntp"
disable_ntp >/dev/null 2>&1
ora_log "disable ntp finish"
#config host
#diable firewall
ora_log "disable firewall"
turn_off_firewall  >/dev/null 2>&1
ora_log "disable firewall finish"


cat  > /etc/hosts <<EOF
127.0.0.1   localhost 
::1         localhost 
$rac1_ip  $rac1_pub_hostname  
$rac1_priv_ip    $rac1_priv_hostname  
$rac1_vip    $rac1_virtual_hostname  

$rac2_ip  $rac2_pub_hostname 
$rac2_priv_ip    $rac2_priv_hostname  
$rac2_vip    $rac2_virtual_hostname  

$rac3_ip  $rac3_pub_hostname 
$rac3_priv_ip    $rac3_priv_hostname  
$rac3_vip    $rac3_virtual_hostname  

$rac4_ip  $rac4_pub_hostname 
$rac4_priv_ip    $rac4_priv_hostname  
$rac4_vip    $rac4_virtual_hostname  

$rac5_ip  $rac5_pub_hostname 
$rac5_priv_ip    $rac5_priv_hostname  
$rac5_vip    $rac5_virtual_hostname  

$rac6_ip  $rac6_pub_hostname 
$rac6_priv_ip    $rac6_priv_hostname  
$rac6_vip    $rac6_virtual_hostname  

$rac7_ip  $rac7_pub_hostname 
$rac7_priv_ip    $rac7_priv_hostname  
$rac7_vip    $rac7_virtual_hostname  

$rac8_ip  $rac8_pub_hostname 
$rac8_priv_ip    $rac8_priv_hostname  
$rac8_vip    $rac8_virtual_hostname  
$racscan_ip   $scanip_hostname
EOF



# set hostname
eval your_host=\$rac${node_num}_pub_hostname
export HOSTNAME=$your_host
hostname $your_host
 [ -f /etc/sysconfig/network ] &&  perl -p -i -e "s/HOSTNAME.*/HOSTNAME=$your_host/" /etc/sysconfig/network
 [ -f /etc/HOSTNAME ] && echo $your_host > /etc/HOSTNAME
#del group adn user

ora_log "setup oracle user and group" 
awk -F:  '{if( $3 == 1001) {print $1}}' /etc/passwd | userdel -r  >& /dev/null 
awk -F:  '{if( $3 == 1002) {print $1}}' /etc/passwd | userdel -r  >& /dev/null

userdel -r oracle  >/dev/null 2>&1 
userdel -r grid    >/dev/null 2>&1
groupdel oinstall  >/dev/null 2>&1
groupdel dba       >/dev/null 2>&1
groupdel oper      >/dev/null 2>&1
groupdel asmadmin  >/dev/null 2>&1
groupdel asmoper   >/dev/null 2>&1
groupdel asmdba    >/dev/null 2>&1
#add group and user
/usr/sbin/groupadd -g 502 oinstall 
/usr/sbin/groupadd -g 503 dba 
/usr/sbin/groupadd -g 504 oper 
/usr/sbin/groupadd -g 505 asmadmin
/usr/sbin/groupadd -g 506 asmoper 
/usr/sbin/groupadd -g 507 asmdba 
/usr/sbin/useradd -m -g oinstall -G dba,asmdba,oper oracle  -u 1001 -o 
/usr/sbin/useradd -m -g oinstall -G asmadmin,asmdba,asmoper,oper,dba grid -u 1002 -o
echo $user_oracle_passwd | passwd oracle --stdin
echo $user_grid_passwd | passwd grid --stdin

ora_log "setup oracle user and group finish" 
#create dir
ora_log "setup oracle directory" 
mkdir -p /home/oracle 
mkdir -p /home/grid 
chown -R oracle:oinstall /home/oracle 
chown -R grid:oinstall /home/grid 
mkdir -p /oracle/app 
chown -R grid:oinstall /oracle/app/ 
chmod -R 775 /oracle/app/ 
mkdir -p /oracle/app/oraInventory 
chown -R grid:oinstall /oracle/app/oraInventory 
chmod -R 775 /oracle/app/oraInventory 
mkdir -p /oracle/app/grid 
mkdir -p /oracle/app/oracle 
chown -R grid:oinstall /oracle/app/grid 
chown -R oracle:oinstall /oracle/app/oracle 
chmod -R 775 /oracle/app/oracle 
chmod -R 775 /oracle/app/grid
ora_log "setup oracle directory finish" 
}
fix_permisson(){
chmod 666 /dev/fuse
chmod 666 /dev/null
chmod 666 /dev/zero
chmod 666 /dev/ptmx
chmod 666 /dev/tty
chmod 666 /dev/full
chmod 666 /dev/urandom
chmod 666 /dev/random
}
uninstall(){

ora_log "delete oracle user and group"
userdel -r oracle >& /dev/null
userdel -r grid  >& /dev/null
groupdel oinstall >& /dev/null
groupdel dba >& /dev/null
groupdel oper >& /dev/null
groupdel asmadmin >& /dev/null
groupdel asmoper >& /dev/null
groupdel asmdba >& /dev/null
ora_log "delete oracle user and group finish"
ora_log "delete oracle file and dir"
rm -rf $grid_oracle_base
rm -rf $grid_oracle_home
rm -rf $oracle_oracle_base
rm -rf $oracle_oracle_home
local oracle_base_base=$(dirname $grid_oracle_base)
local grid_base_base=$(dirname $oracle_oracle_base)
rm -rf ${oracle_base_base}/oraInventory
rm -rf ${grid_base_base}/oraInventory
rm -rf /etc/ora*
rm -rf /tmp/.oracle
rm -rf /var/tmp/.oracle
rm -rf /etc/inittab.crs
 [ -f  /etc/initab.no_crs ]  && cp -rf /etc/inittab.no_crs /etc/inittab
ora_log "delete oracle file and dir finish"
ora_log "dd disk in raw"
for disk in  $(rac_data_disk_list) $(rac_crs_disk_list)
do
    while :
    do
        ora_log "Make Sure you need to format $disk (y/n):"
        read  REPLY
        case $REPLY in
            y|Y)
            dd if=/dev/zero of=$disk bs=1024 count=5000
            break 1
            ;;
            n|N)
            echo "Format by yourself"
            echo dd if=/dev/zero of=$disk bs=1024 count=5000
            break 1
            ;;
            *)
            echo "input error"
            continue 1
            ;;
        esac
    done
done
ora_log "dd disk in raw finish"

rm -rf /etc/init.d/init.ohasd
rm -rf /etc/init.d/ohasd
rm -rf /tmp/CVU_*
rm -rf /tmp/OraInsta*
rm -rf /opt/ORCLfmap
rm -rf /usr/local/bin/dbhome
rm -rf /usr/local/bin/oraenv 
rm -rf /usr/local/bin/coraenv
ora_log "single node uninstall  finish  "

}

user_env(){
ora_log "make bash_profile for user grid, oracle "
cat > /home/grid/.bash_profile <<EOF
ORACLE_SID=+ASM${node_num}; export ORACLE_SID 
ORACLE_BASE=${grid_oracle_base}; export ORACLE_BASE 
ORACLE_HOME=${grid_oracle_home}; export ORACLE_HOME
PATH=\$ORACLE_HOME/bin:\$PATH; export PATH 
LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
EOF

cat > /home/oracle/.bash_profile <<EOF
ORACLE_BASE=${oracle_oracle_base}; export ORACLE_BASE 
ORACLE_HOME=${oracle_oracle_home}; export ORACLE_HOME 
ORACLE_SID=${oracle_sid_prefix}${node_num}; export ORACLE_SID
PATH=\$ORACLE_HOME/bin:\$PATH; export PATH 
LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
EOF
chown grid:oinstall /home/grid/.bash_profile
chown oracle:oinstall /home/oracle/.bash_profile
chmod 644 /home/grid/.bash_profile
chmod 644 /home/oracle/.bash_profile
}

case $1 in
  install) 
	node_num=$2 
        if [ X$node_num == X"" ]
        then
            echo "usage:$0  install nodenum "
            exit 1
        fi
        restore_file >& /dev/null
        backup_file  >& /dev/null
        set_env
        user_env
        fix_permisson
        ;;
  uninstall)
        restore_file
        uninstall
        ;;
   *)
        echo "usage:$0 [install nodenum | uninstall] "
       ;;
esac
exit 0 


