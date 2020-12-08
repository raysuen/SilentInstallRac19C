#!/bin/bash
#by raysuen
#v01
#################################################################################
#执行脚本前：
#	1. 创建实例前确认存储数据的磁盘组存在
#	2. 安装包放在oracle家目录内
#
#################################################################################


. ~/.bash_profile

####################################################################################
#unzip oracle rdbms software and install rdbms
####################################################################################
UnzipAndInstallRdbms(){
	echo "${ORACLE_HOME}" | awk -F"/" '{if($NF=="") {print "rm -rf "$0"*"} else {print "rm -rf "$0"/*"}}' | bash
	if [ -f ~/LINUX.X64_193000_db_home.zip ];then
		unzip ~/LINUX.X64_193000_db_home.zip -d ${ORACLE_HOME}
		[ $? -ne 0 ] && exit 98
	else
		echo "The DB zip not find in oracle home."
		exit 99
	fi
	NodeList=`sed -n '/^#public ip/,/^#private ip/p' /etc/hosts | egrep "^[[:digit:]]" | awk '{printf $2","}' | awk '{print substr($0,1,length($0)-1)}'`
	${ORACLE_HOME}/runInstaller -ignorePrereq -waitforcompletion -silent \
   		-responseFile ${ORACLE_HOME}/install/response/db_install.rsp \
   		oracle.install.option=INSTALL_DB_SWONLY \
   		UNIX_GROUP_NAME=oinstall \
   		INVENTORY_LOCATION=${ORACLE_BASE}/oraInventory \
   		SELECTED_LANGUAGES=en,en_GB \
   		ORACLE_HOME=${ORACLE_HOME} \
   		ORACLE_BASE=${ORACLE_BASE} \
   		oracle.install.db.InstallEdition=EE \
		oracle.install.db.OSDBA_GROUP=dba \
		oracle.install.db.OSOPER_GROUP=oper \
		oracle.install.db.OSBACKUPDBA_GROUP=backupdba \
		oracle.install.db.OSDGDBA_GROUP=dgdba \
		oracle.install.db.OSKMDBA_GROUP=kmdba \
		oracle.install.db.OSRACDBA_GROUP=racdba \
		oracle.install.db.rootconfig.executeRootScript=false \
		oracle.install.db.CLUSTER_NODES=${NodeList} \
		oracle.install.db.ConfigureAsContainerDB=false \
		oracle.install.db.config.starterdb.memoryOption=false \
		oracle.install.db.config.starterdb.installExampleSchemas=false \
		oracle.install.db.config.starterdb.managementOption=DEFAULT \
		oracle.install.db.config.starterdb.omsPort=0 \
		oracle.install.db.config.starterdb.enableRecovery=false
		
}

####################################################################################
#install instance
####################################################################################
InstallInstance(){
	#NodeList=`sed -n '/^#public ip/,/^#private ip/p' /etc/hosts | egrep "^[[:digit:]]" | awk '{printf $2","}' | awk '{print substr($0,1,length($0)-1)}'`
	
	while true
	do
		read -p "`echo -e "Do you go on to install instance,\e[1;33m yes/no \e[0m : "`" InstanceConfirm
		if [ "${InstanceConfirm}" == "yes" ];then
			break
		elif [ "${InstanceConfirm}" == "no" ];then
			exit 0
		else
			echo "You only enter yes or no."
			continue
		fi
	done
	
	while true
	do
		####################################################################################
		#get SID prefix
		####################################################################################
		read -p "`echo -e "please enter the sid and db name prefix.default \e[1;33m orcl \e[0m: "`" osid
		[ ${osid} ] || osid="orcl"
		
		####################################################################################
		#get characterSet
		####################################################################################
		while true
		do
			echo "please enter the characterSet for your instance."
			echo "(1) ZHS16GBK"
			echo "(2) AL32UTF8"
			read -p "`echo -e ".Please enter 1 or 2 to choose character: "`" Inchar
			if [ ! ${Inchar} ];then
				echo "You must enter 1 or 2 to choose the character."
				continue
			elif [ ${Inchar} -eq 1 ];then
				InCharacter=ZHS16GBK  #this is character of instance. 
				break
			elif [ ${Inchar} -eq 2 ];then
				InCharacter=AL32UTF8  #this is character of instance. 
				break
			else
				echo "You must enter 1 or 2 to choose the character."
				continue
			fi
		done
		
		####################################################################################
		#get diskgroup for datafile location
		####################################################################################
		while true
		do
			read -p "`echo -e ".Please specify a diskgroup for datafile location: "`" DiskGroupName
			[ ${DiskGroupName} ]&& break || continue
		done	
		
		####################################################################################
		#get SGA PGA  
		####################################################################################
		while true
		do
			read -p "`echo -e ".Please specify SGA size,default MB,you also use G. : "`" SGASize
			if [ ! ${SGASize} ];then
				echo "You must specify a value for sga."
				continue
			fi
			if [ ! `echo ${SGASize} | sed 's/[[:digit:]]//g'` ];then
				SGASize=${SGASize}"MB"
				break
			elif [ `echo ${SGASize} | sed 's/[[:digit:]]//g'` == "G" ];then
				break
			elif [ `echo ${SGASize} | sed 's/[[:digit:]]//g'` == "M" ];then
				break
			else
				echo "You must specify right a value for sga."
				echo "Example: 4096 or 4096M or 4G"
				echo ""
				continue
			fi
		done
		while true
		do
			read -p "`echo -e "Please specify PGA size,default MB,you also use G. : "`" PGASize
			if [ ! ${PGASize} ];then
				echo "You must specify a value for pga."
				continue
			fi
			if [ ! `echo ${PGASize} | sed 's/[[:digit:]]//g'` ];then
				PGASize=${PGASize}"MB"
				break
			elif [ `echo ${PGASize} | sed 's/[[:digit:]]//g'` == "G" ];then
				break
			elif [ `echo ${PGASize} | sed 's/[[:digit:]]//g'` == "M" ];then
				break
			else
				echo "You must specify right a value for sga."
				echo "Example: 4096 or 4096M or 4G"
				echo ""
				continue
			fi
		done
		
		####################################################################################
		#get container
		####################################################################################
		while true
		do
			read -p "`echo -e "Do you create container database？ yes/no. Default \e[1;33m no \e[0m: "`" ContainerConfirm
			if [ ${ContainerConfirm:-no} == "no" ];then
				break
			elif [ ${ContainerConfirm:-no} == "yes" ];then
				read -p "`echo -e "PDB name:  "`" PDBName
				if [ ! ${PDBName} ];then
					echo "PDB name must be not empty!"
					continue
				else
					break
				fi
			else
				echo "You only enter yes or no."
				continue
			fi
		done
		
		####################################################################################
		#confirm all infomation
		####################################################################################
		echo ""
		echo -e "\e[1;31mYour instance name is ${osid} \e[0m"
		echo -e "\e[1;31mYour instance characterset is ${InCharacter} \e[0m"
		echo -e "\e[1;31mYour instance datafile location is ${DiskGroupName} \e[0m"
		echo -e "\e[1;31mYour instance SGA is ${SGASize} \e[0m"
		echo -e "\e[1;31mYour instance PGA is ${PGASize} \e[0m"
		if [ "${ContainerConfirm}" == "yes" ];then
			echo -e "\e[1;31mYour instance PDB name is ${PDBName} \e[0m"
		fi
		echo ""
		while true
		do
			read -p "`echo -e "Please confirm instance information. yes/no. Default \e[1;33m yes \e[0m: "`" InfoConfirm
			if [ "${InfoConfirm:-yes}" == "yes"  ];then
				break
			elif [ "${InfoConfirm:-yes}" == "no"  ];then
				break
			else
				echo "You only enter yes or no."
				continue
			fi
		done
		if [ "${InfoConfirm:-yes}" == "yes"  ];then
			break
		else
			continue
		fi
		
	done

	####################################################################################
	#install instance
	####################################################################################
	if [ ${ContainerConfirm:-no} == "no" ];then
		dbca -silent -ignorePreReqs -createDatabase \
		-templateName General_Purpose.dbc  \
		-databaseConfigType RAC \
		-gdbName ${osid} \
		-sid ${osid} \
		-sysPassword oracle \
		-systemPassword oracle \
		-dbsnmpPassword oracle \
		-characterSet ${InCharacter} \
		-nationalCharacterSet AL16UTF16  \
		-storageType ASM \
		-diskGroupName +${DiskGroupName} \
		-nodelist ${NodeList} \
		-asmSysPassword oracle \
		-initParams processes=1500,pga_aggregate_target=${PGASize},sga_target=${SGASize}
	else
		dbca -silent -ignorePreReqs -createDatabase \
		-templateName General_Purpose.dbc  \
		-databaseConfigType RAC \
		-gdbName ${osid} \
		-sid ${osid} \
		-sysPassword oracle \
		-systemPassword oracle \
		-dbsnmpPassword oracle \
		-characterSet ${InCharacter} \
		-nationalCharacterSet AL16UTF16  \
		-storageType ASM \
		-diskGroupName +${DiskGroupName} \
		-nodelist ${NodeList} \
		-asmSysPassword oracle \
		-initParams processes=1500,pga_aggregate_target=${PGASize},sga_target=${SGASize} \
		-createAsContainerDatabase true \
		-pdbName ${PDBName} \
		-numberOfPDBs 1 \
		-pdbAdminPassword oracle

	fi
	
	
		
}

####################################################################################
#entrance of script
####################################################################################
#UnzipAndInstallRdbms
InstallInstance





