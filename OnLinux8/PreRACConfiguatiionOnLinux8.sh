#!/bin/bash
#by raysueen
#v1.2


#################################################################################
#执行脚本前：
#	1. 把脚本放入基础目录，例如：/u01
#   2. 挂载ISO
#	3. 把需要本地安装的rpm上传到基础目录,libnsl2-devel
#	4. 设置好主机名
#执行脚本后：
#	1. 手动绑定磁盘,或安装asmlib并创建disk
#	2. 在hosts文件内把VIP和scan的IP修改正确，并其他节点信息添加进去
#	3. 通过提示把ssh互信完成。
#################################################################################


DefaultUserPWD="**********"  #set a password for grid and oracle


####################################################################################
#install rpm that oracle is necessary for installing
####################################################################################
InstallRPM(){
	mountPatch=`mount | egrep "iso|ISO|^/dev/sr" | awk '{print $3}'`
	if [ ! ${mountPatch} ];then
		echo "No ios file is mounted. Please check whether the YUM/DNF command can install the RPM package."
        	while true
            do
				read -p "`echo -e "Go on to install? [${c_yellow}yes/no${c_end}]: "`" isgo
				if [ ! ${isgo} ];then
					echo -e "${c_yellow}You must enter yes or no.${c_end}"
					continue
				elif [ ${isgo} == "yes" ];then
					break
				elif [ ${isgo} == "no" ];then
					exit 0
				fi
            done
    else
    	if [ -d /etc/yum.repos.d/`date +"%Y%m%d"` ];then
			[ `ls /etc/yum.repos.d/*.repo | grep -v "local*" | wc -l` -gt 0 ] && mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/`date +"%Y%m%d"`/
		else
			if [ `ls /etc/yum.repos.d/*.repo | grep -v "local*" | wc -l` -gt 0 ];then
		 		mkdir -p /etc/yum.repos.d/`date +"%Y%m%d"` && mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/`date +"%Y%m%d"`/
			fi
		fi 
    	[ -f "/etc/yum.repos.d/local.repo" ] && sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /etc/yum.repos.d/local.repo
    	echo "
#OraConfBegin
[InstallMedia-BaseOS]
name=Red Hat Enterprise Linux 8 - BaseOS
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file://${mountPatch}/BaseOS/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[InstallMedia-AppStream]
name=Red Hat Enterprise Linux 8 - AppStream
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file://${mountPatch}/AppStream/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
#OraConfBegin
" >> /etc/yum.repos.d/local.repo

	fi
	dnf -y install bc --nogpgcheck
	dnf -y install binutils --nogpgcheck
	dnf -y install elfutils-libelf --nogpgcheck
	dnf -y install elfutils-libelf-devel --nogpgcheck
	dnf -y install fontconfig-devel --nogpgcheck
	dnf -y install glibc --nogpgcheck
	dnf -y install glibc-devel --nogpgcheck
	dnf -y install ksh --nogpgcheck
	dnf -y install libaio --nogpgcheck
	dnf -y install libaio-devel --nogpgcheck
	dnf -y install libXrender --nogpgcheck
	dnf -y install libX11 --nogpgcheck
	dnf -y install libXau --nogpgcheck
	dnf -y install libXi --nogpgcheck
	dnf -y install libXtst --nogpgcheck
	dnf -y install libgcc --nogpgcheck
	dnf -y install libnsl --nogpgcheck
	dnf -y install librdmacm --nogpgcheck
	dnf -y install libstdc++ --nogpgcheck
	dnf -y install libstdc++-devel --nogpgcheck
	dnf -y install libxcb --nogpgcheck
	dnf -y install libibverbs --nogpgcheck
	dnf -y install make --nogpgcheck
	dnf -y install policycoreutils --nogpgcheck
	dnf -y install policycoreutils-python-utils --nogpgcheck
	dnf -y install smartmontools --nogpgcheck
	dnf -y install sysstat --nogpgcheck
	dnf -y install ipmiutil --nogpgcheck
	dnf -y install libnsl2 --nogpgcheck
	dnf -y install libnsl2-devel  --nogpgcheck
	dnf -y install net-tools --nogpgcheck
	dnf -y install nfs-utils --nogpgcheck
	dnf -y install unixODBC --nogpgcheck

	#dnf localinstall ./libnsl2-devel-1.2.0-2.20180605git4a062cf.el8.x86_64.rpm  --nogpgcheck
	# -y localinstall compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm 
	#yum -y localinstall elfutils-libelf-devel-0.168-8.el7.x86_64.rpm
	[ `ls ${basedir}/libnsl2-devel* 2>/dev/null | wc -l` -eq 1 ] && ls ${basedir}/libnsl2-devel* | awk -v rpmpackage="" '{rpmpackage=$NF" "rpmpackage}END{print "dnf -y localinstall "rpmpackage" --nogpgcheck"}' | bash 
	while true
	do
		if [ `rpm -q unzip bc binutils elfutils-libelf elfutils-libelf-devel fontconfig-devel glibc glibc-devel ksh libaio libaio-devel libXrender libX11 libXau libXi libXtst libgcc libnsl librdmacm libstdc++ libstdc++-devel libxcb libibverbs make policycoreutils policycoreutils-python-utils smartmontools sysstat ipmiutil libnsl2 libnsl2-devel  net-tools nfs-utils unixODBC  --qf '%{name}.%{arch}\n' | grep "not installed" | wc -l` -gt 0 ];then
			echo -e "${c_yellow}RPM not intalled list${c_end}:"
			rpm -q unzip bc binutils elfutils-libelf elfutils-libelf-devel fontconfig-devel glibc glibc-devel ksh libaio libaio-devel libXrender libX11 libXau libXi libXtst libgcc libnsl librdmacm libstdc++ libstdc++-devel libxcb libibverbs make policycoreutils policycoreutils-python-utils smartmontools sysstat ipmiutil libnsl2 libnsl2-devel  net-tools nfs-utils unixODBC  --qf '%{name}.%{arch}\n' | grep "not installed"
			echo " "
			read -p "`echo -e "Please confirm that all rpm package have installed.[${c_yellow}yes/no${c_end}] default yes:"`" ans
			if [ "${ans:-yes}" == "yes" ];then
				break
			else
				continue
			fi
		else
			break
		fi
	done
}



####################################################################################
# create user and groups 
####################################################################################
CreateUsersAndDirs(){
	####################################################################################
	# create user and groups 
	####################################################################################
	if [ `egrep "oinstall" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11001 oinstall  
	fi
	if [ `egrep "dba" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11002 dba  
	fi
	if [ `egrep "oper" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11003 oper  
	fi
	if [ `egrep "backupdba" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11004 backupdba  
	fi
	if [ `egrep "dgdba" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11005 dgdba  
	fi
	if [ `egrep "kmdba" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11006 kmdba  
	fi
	if [ `egrep "asmdba" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11007 asmdba  
	fi
	if [ `egrep "asmoper" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11008 asmoper  
	fi
	if [ `egrep "asmadmin" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11009 asmadmin  
	fi
	if [ `egrep "racdba" /etc/group | wc -l` -eq 0 ];then
		groupadd -g 11010 racdba  
	fi
	
	
	if [ `egrep "grid" /etc/passwd | wc -l` -eq 0 ];then
		useradd -u 11012 -g oinstall -G asmadmin,asmdba,asmoper,dba grid
		if [ $? -ne 0 ];then
			echo "Command failed to adding user --grid."
			exit  93
		fi
	else
		usermod -g oinstall -G asmadmin,asmdba,asmoper,dba grid
	fi
	if [ `egrep "oracle" /etc/passwd | wc -l` -eq 0 ];then
		useradd -u 11011 -g oinstall -G dba,asmdba,backupdba,dgdba,kmdba,racdba,oper oracle   
		if [ $? -ne 0 ];then
			echo "Command failed to adding user --oracle."
			exit  93
		fi
	else
		usermod -g oinstall -G dba,asmdba,backupdba,dgdba,kmdba,racdba,oper oracle  
	fi

	echo "${DefaultUserPWD}" | passwd --stdin grid
	if [ $? -ne 0 ];then
		echo "Grid is not existing."
		exit  92
	fi
	echo "${DefaultUserPWD}" | passwd --stdin oracle
	if [ $? -ne 0 ];then
		echo "Oracle is not existing."
		exit  92
	fi
	
	####################################################################################
	#make directory
	####################################################################################
	[ ! -d /u01/app/19.0.0/grid ] && mkdir -p /u01/app/19.0.0/grid
	[ ! -d /u01/app/grid ] && mkdir -p /u01/app/grid
	[ ! -d /u01/app/oracle ] && mkdir -p /u01/app/oracle
	[ ! -d /u01/app/oracle/product/19.0.0/db_1 ] && mkdir -p /u01/app/oracle/product/19.0.0/db_1
	chown -R grid:oinstall /u01/app/grid
	chown -R grid:oinstall /u01/app/19.0.0
	chown -R oracle:oinstall /u01/app/oracle
	chmod -R 775 /u01/

	
}

 
####################################################################################
#Time dependent Settings
####################################################################################
TimeDepSet(){
	timedatectl set-timezone Asia/Shanghai
	systemctl stop ntpd.service
	systemctl disable ntpd.service
	[ -f /etc/ntp.conf ] && mv /etc/ntp.conf /etc/ntp.conf.orig
	systemctl stop chronyd.service
	systemctl disable chronyd.service


}

####################################################################################
#Time dependent Settings
####################################################################################
Stopavahi(){
	systemctl stop avahi-daemon.socket
	systemctl disable avahi-daemon.socket
	systemctl stop avahi-daemon.service
	systemctl disable avahi-daemon.service
	ps -ef|grep avahi-daemon | egrep -v "grep" | awk '{print "kill -9 "$2}'

}

####################################################################################
#stop firefall  and disable selinux
####################################################################################
StopFirewallAndDisableSelinux(){
	systemctl stop firewalld
	systemctl disable firewalld
	if [ "`/usr/sbin/getenforce`" != "Disabled" ];then
		/usr/sbin/setenforce 0
	fi
	if [ ! -z `grep "SELINUX=enforcing" /etc/selinux/config` ];then
		[ ! -f /etc/selinux/config.$(date +%F) ] && cp /etc/selinux/config /etc/selinux/config.$(date +%F)
		sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	fi
	
}

####################################################################################
#edit parameter
####################################################################################
EditParaFiles(){
	####################################################################################
	#obtain current day
	####################################################################################
	daytime=`date +%Y%m%d`
	####################################################################################
	#ban hugepage
	####################################################################################
	sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /etc/default/grub
	sed -i 's/^GRUB_CMDLINE_LINUX/#GRUB_CMDLINE_LINUX/g' /etc/default/grub
	echo "#OraConfBegin" >> /etc/default/grub
	bugestring=`awk '/GRUB_CMDLINE_LINUX/{sub(/"$/," ",$NF);sub(/^#/,"",$1);print $0" numa=off transparent_hugepage=never\""}' /etc/default/grub`
	echo  ${bugestring} >> /etc/default/grub
	echo "#OraConfEnd" >> /etc/default/grub
	grub2-mkconfig -o /boot/grub2/grub.cfg
	
	####################################################################################
	#edit limits.conf
	####################################################################################
	sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /etc/security/limits.conf
	[ ! -f /etc/security/limits.conf.${daytime} ] && cp /etc/security/limits.conf /etc/security/limits.conf.${daytime}
	echo "#OraConfBegin" >> /etc/security/limits.conf
	echo "grid  soft  nproc 2047" >> /etc/security/limits.conf
	echo "grid  hard  nproc 16384" >> /etc/security/limits.conf
	echo "grid  soft  nofile 1024" >> /etc/security/limits.conf
	echo "grid  hard  nofile 65536" >> /etc/security/limits.conf
	echo "grid  soft  stack 10240" >> /etc/security/limits.conf
	echo "grid  hard  stack 32768" >> /etc/security/limits.conf
	echo "oracle soft nproc 2047" >> /etc/security/limits.conf
	echo "oracle hard nproc 16384" >> /etc/security/limits.conf
	echo "oracle soft nofile 1024" >> /etc/security/limits.conf
	echo "oracle hard nofile 65536" >> /etc/security/limits.conf
	echo "oracle soft stack  10240" >> /etc/security/limits.conf
	echo "oracle hard stack  32768" >> /etc/security/limits.conf
	echo "oracle hard memlock 4194304" >> /etc/security/limits.conf
	echo "oracle soft memlock 4194304" >> /etc/security/limits.conf
	echo "#OraConfEnd" >> /etc/security/limits.conf
	
	####################################################################################
	#edit sysctl.conf
	####################################################################################
	shmall=`/sbin/sysctl -a 2>&1 | grep "shmall" | awk '{print $NF}'`
	shmmax=`/sbin/sysctl -a 2>&1 | grep "shmmax" | awk '{print $NF}'`
	
	sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /etc/sysctl.conf #delete content
	[ ! -f /etc/sysctl.conf.${daytime} ] && cp /etc/sysctl.conf /etc/sysctl.conf.${daytime}
	echo "#OraConfBegin" >> /etc/sysctl.conf
	echo "fs.aio-max-nr = 1048576" >> /etc/sysctl.conf
	echo "fs.file-max = 6815744" >> /etc/sysctl.conf
	echo "kernel.shmall = "${shmall} >> /etc/sysctl.conf
	echo "kernel.shmmax = "${shmall} >> /etc/sysctl.conf
	echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
	echo "kernel.sem = 250 32000 100 128" >> /etc/sysctl.conf
	echo "net.ipv4.ip_local_port_range = 9000 65500" >> /etc/sysctl.conf
	echo "net.core.rmem_default = 262144" >> /etc/sysctl.conf
	echo "net.core.rmem_max = 4194304" >> /etc/sysctl.conf
	echo "net.core.wmem_default = 262144" >> /etc/sysctl.conf
	echo "net.core.wmem_max = 1048576" >> /etc/sysctl.conf
	echo "#OraConfEnd" >> /etc/sysctl.conf
	
	sysctl -p
	
	####################################################################################
	#edit nsysctl.conf	
	####################################################################################
	
	sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /etc/sysconfig/network #delete content
	[ ! -f /etc/sysconfig/network.${daytime} ] && cp /etc/sysconfig/network /etc/sysconfig/network.${daytime}
	echo "#OraConfBegin" >> /etc/sysconfig/network
	echo "NOZEROCONF=yes" >> /etc/sysconfig/network
	echo "#OraConfEnd" >> /etc/sysconfig/network
}

####################################################################################
#obtain base dir
####################################################################################
ObtainBasedir(){
	if [ "${basedir:-None}" == "None" ];then
		while true
		do
			read -p "`echo -e "please enter the name of base dir,put this shell and software in the dir.default [\e[1;33m/u01\e[0m]: "`" bdir
			basedir=${bdir:-/u01}  #this is base dir,put this shell and software in the dir
			if [ ! -d ${basedir} ];then
		    	echo -e "the ${basedir} is not exsist,please ${c_red}make it up${c_end}"
		    	continue
			else
		    	break
		  	fi
		done
	else
		if [ ! -d ${basedir} ];then
			echo -e "the ${basedir} is not exsist,please ${c_red}make it up${c_end}"
			exit 95
		fi
	fi 
}

####################################################################################
#edit bash_profile
####################################################################################
EditUserBashprofile(){
	####################################################################################
	#obtain current day
	####################################################################################
	daytime=`date +%Y%m%d`

	####################################################################################
	#obtain path
	####################################################################################
	gridbase="${basedir}/app/grid"
	gridhome="${basedir}/app/19.0.0/grid"
	orabase="${basedir}/app/oracle"    #set path of oracle_base
	orahome="${orabase}/product/19.0.0/db_1"
	####################################################################################
	#edit grid's bash
	####################################################################################
	while true
	do
		read -p "`echo -e "\e[1;33mPlease enter a number to indicate the current node。： \e[0m"`" NodeNum
		[ `grep '^[[:digit:]]*$' <<< "${NodeNum}"` ] && break || echo -e "\e[1;33You must enter a number!!.\e[0m";continue
		
	done
	[ ! -f /home/grid/.bash_profile${daytime}.bak ] && su - grid -c "cp /home/grid/.bash_profile /home/grid/.bash_profile${daytime}.bak"
	[ -f /home/grid/.bash_profile ] && su - grid -c "sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /home/grid/.bash_profile"
	su - grid -c "echo \"#OraConfBegin\" >> /home/grid/.bash_profile"
	su - grid -c "echo 'ORACLE_BASE='${gridbase} >> /home/grid/.bash_profile"
	su - grid -c "echo 'ORACLE_HOME='${gridhome} >> /home/grid/.bash_profile"
	su - grid -c "echo 'ORACLE_SID=+ASM'${NodeNum} >> /home/grid/.bash_profile"
	su - grid -c "echo 'export ORACLE_BASE ORACLE_HOME ORACLE_SID' >> /home/grid/.bash_profile"
	su - grid -c "echo 'export PATH=\$PATH:\$HOME/bin:\$ORACLE_HOME/bin' >> /home/grid/.bash_profile"
	#su - grid -c "echo 'export NLS_LANG=AMERICAN_AMERICA.AL32UTF8' >> /home/grid/.bash_profile"           #AL32UTF8,ZHS16GBK
	su - grid -c "echo 'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$ORACLE_HOME/lib' >> /home/grid/.bash_profile"
	su - grid -c "echo 'export CV_ASSUME_DISTID=OEL7' >> /home/grid/.bash_profile"
	su - grid -c "echo \"#OraConfEnd\" >> /home/grid/.bash_profile"
	####################################################################################
	#edit oracle's bash
	####################################################################################
	[ ! -f /home/oracle/.bash_profile${daytime}.bak ] && su - oracle -c "cp /home/oracle/.bash_profile /home/oracle/.bash_profile${daytime}.bak"
	[ -f home/oracle/.bash_profile ] && su - oracle -c "sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /home/oracle/.bash_profile"
	su - oracle -c "echo \"#OraConfBegin\" >> /home/oracle/.bash_profile"
	su - oracle -c "echo 'ORACLE_BASE='${orabase} >> /home/oracle/.bash_profile"
	su - oracle -c "echo 'ORACLE_HOME='${orahome} >> /home/oracle/.bash_profile"
	su - oracle -c "echo 'ORACLE_SID=' >> /home/oracle/.bash_profile"
	su - oracle -c "echo 'export ORACLE_BASE ORACLE_HOME ORACLE_SID' >> /home/oracle/.bash_profile"
	su - oracle -c "echo 'export PATH=\$PATH:\$HOME/bin:\$ORACLE_HOME/bin' >> /home/oracle/.bash_profile"
	#su - oracle -c "echo 'export NLS_LANG=AMERICAN_AMERICA.AL32UTF8' >> /home/oracle/.bash_profile"           #AL32UTF8,ZHS16GBK
	su - oracle -c "echo 'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$ORACLE_HOME/lib' >> /home/oracle/.bash_profile"
	su - oracle -c "echo 'export CV_ASSUME_DISTID=OEL7' >> /home/oracle/.bash_profile"
	su - oracle -c "echo \"#OraConfEnd\" >> /home/oracle/.bash_profile"
	
	
}

####################################################################################
#create keygen
####################################################################################
EditHostsFile(){
	####################################################################################
	#list internet name
	####################################################################################
	echo "internet name:"
	for i in `ip addr | egrep "^[0-9]" | awk -F ':' '{print $2}'`
	do
        IPtemp=`ifconfig $i | egrep -v "inet6" | awk -F 'net|netmaskt' '{print $2}' | sed ':label;N;s/\n//;b label' | sed -e 's/ //g' -e 's/)//g'`
        printf "%10s : %-20s\n" $i ${IPtemp}
        #echo -e "      \e[1;33m"$i": "`ifconfig $i | egrep -v "inet6" | awk -F 'net|netmaskt' '{print $2}' | sed ':label;N;s/\n//;b label' | sed -e 's/ //g' -e 's/)//g'`"\e[0m"
	done
	####################################################################################
	#get public internet
	####################################################################################
	while true
	do
		read -p "`echo -e "\e[1;33mPlease enter internet name for public :  \e[0m"`" PublicName
		[ `ip addr | egrep "^[0-9]" | awk -F ':' '{print $2}' | egrep "${PublicName}"` ] && break || echo "Please enter a right internet name!!";continue
		
	done
	####################################################################################
	#get private internet
	####################################################################################
	while true
	do
		read -p "`echo -e "\e[1;33mPlease enter internet name for private :  \e[0m"`" PrivateName
		[ `ip addr | egrep "^[0-9]" | awk -F ':' '{print $2}' | egrep "${PrivateName}"` ] && break || echo "Please enter a right internet name!!";continue
		
	done
	HName=`/bin/hostname`
	#ip add | grep ens192 | grep inet | awk '{print $2}' | awk -F"/" '{printf "%-20s'${HName}'\n",$1}'
	sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /etc/hosts
	echo "" >> /etc/hosts
	echo "#OraConfBegin" >> /etc/hosts
	echo "#public ip" >> /etc/hosts
	ip add | grep ${PublicName} | grep inet | awk '{print $2}' | awk -F"/" '{printf "%-20s'${HName}'\n",$1}' >> /etc/hosts
	echo "" >> /etc/hosts
	echo "" >> /etc/hosts
	echo "#private ip" >> /etc/hosts
	ip add | grep ${PrivateName} | grep inet | awk '{print $2}' | awk -F"/" '{printf "%-20s'${HName}'-priv\n",$1}' >> /etc/hosts
	echo "" >> /etc/hosts
	echo "" >> /etc/hosts
	echo "#Vip" >> /etc/hosts
	ip add | grep ${PublicName} | grep inet | awk '{print $2}' | awk -F"[./]" '{printf "%-20s'${HName}'-vip\n",$1"."$2"."$3"."}' >> /etc/hosts
	echo "" >> /etc/hosts
	echo "" >> /etc/hosts
	echo "#scan ip" >> /etc/hosts
	ip add | grep ${PublicName} | grep inet | awk '{print $2}' | awk -F"[./]" '{printf "%-20sracscan\n",$1"."$2"."$3"."}' >> /etc/hosts
	echo "" >> /etc/hosts
	echo "#OraConfEnd" >> /etc/hosts
}

####################################################################################
#create keygen
####################################################################################
CreateKeygen(){
	su - grid -c "rm -rf ~/.ssh"
	su - grid -c "echo -e \"\\n\\n\\n\\n\" | ssh-keygen -t rsa"
	su - grid -c "echo -e \"\\n\\n\\n\\n\" | ssh-keygen -t dsa"
	su - grid -c "cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys"
	su - grid -c "cat ~/.ssh/id_dsa.pub >>~/.ssh/authorized_keys"
	su - oracle -c "rm -rf ~/.ssh"
	su - oracle -c "echo -e \"\\n\\n\\n\\n\" | ssh-keygen -t rsa"
	su - oracle -c "echo -e \"\\n\\n\\n\\n\" | ssh-keygen -t dsa"
	su - oracle -c "cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys"
	su - oracle -c "cat ~/.ssh/id_dsa.pub >>~/.ssh/authorized_keys"
	echo -e "\e[1;33mIf this is first node in RAC,you can exec following command as grid and oracle,not ignore following.\e[0m"
	echo -e "\e[1;33m	ssh OtherNode cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys\e[0m"
	echo -e "\e[1;33m	ssh OtherNode cat ~/.ssh/id_dsa.pub >>~/.ssh/authorized_keys\e[0m" 
	echo -e "\e[1;33m	scp ~/.ssh/authorized_keys OtherNode:~/.ssh/authorized_keys\e[0m" 
	
}

####################################################################################
#edit scp
####################################################################################
EditSCP(){
	if [ -f /usr/bin/scp.orig ];then
		[ -f /usr/bin/scp ] && sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /usr/bin/scp
		echo "#OraConfBegin" >> /usr/bin/scp
		echo "/usr/bin/scp.orig -T \$*" >>  /usr/bin/scp
		echo "#OraConfEnd" >> /usr/bin/scp
	else 
		mv /usr/bin/scp /usr/bin/scp.orig
		[ -f /usr/bin/scp ] && sed -i '/^#OraConfBegin/,/^#OraConfEnd/d' /usr/bin/scp
		echo "#OraConfBegin" >> /usr/bin/scp
		echo "/usr/bin/scp.orig -T \$*" >>  /usr/bin/scp
		echo "#OraConfEnd" >> /usr/bin/scp
	fi
	chmod 555 /usr/bin/scp
}

####################################################################################
#run function
####################################################################################
RunFunction(){
	ObtainBasedir 
	InstallRPM   
	CreateUsersAndDirs   
	TimeDepSet
	Stopavahi
	StopFirewallAndDisableSelinux   
	EditParaFiles
	EditSCP      
	EditUserBashprofile      
	EditHostsFile
	CreateKeygen
}


####################################################################################
#entrance of the script
####################################################################################
RunFunction