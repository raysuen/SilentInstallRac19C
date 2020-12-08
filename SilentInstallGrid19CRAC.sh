#!/bin/bash
#by raysuen
#v01
#################################################################################
#执行脚本前：
#	1. 确认是否绑定磁盘，或使用asmlib创建磁盘。
#   2. 在/etc/hosts文件内的IP信息是否准确。
#	3. 确认ssh互信完成。
#	
#
#################################################################################



. ~/.bash_profile

####################################################################################
#unzip Grid
####################################################################################
UnzipPRMAndCheck(){
	echo "${ORACLE_HOME}" | awk -F"/" '{if($NF=="") {print "rm -rf "$0"*"} else {print "rm -rf "$0"/*"}}' | bash
	if [ -f ~/LINUX.X64_193000_grid_home.zip ];then
		unzip ~/LINUX.X64_193000_grid_home.zip -d ${ORACLE_HOME}
		[ $? -ne 0 ] && exit 98
		echo -e "\e[1;33mExecute the following command as root on current node: \e[0m"
		if [ -d ${ORACLE_HOME}/cv/rpm ];then
			CvRpmName=`ls ${ORACLE_HOME}/cv/rpm`
			 echo ${CvRpmName} | awk '{print "    rpm -ivh '${ORACLE_HOME}'/cv/rpm/"$0}'
		fi
		HostnameArray=$(sed -n '/^#public ip/,/^#private ip/p' /etc/hosts | egrep "^[[:digit:]]" | awk '{if($2!=cmd) print $2}' cmd=`hostname`)
		for var in ${HostnameArray[@]}
		do
			scp ${ORACLE_HOME}/cv/rpm/${CvRpmName} $var:/tmp
		done
		echo -e "\e[1;33mExecute the following command as root on remode node: \e[0m"
		echo -e "\e[1;33m	rpm -ivh /tmp/${CvRpmName}\e[0m"
		while true
		do
			read -p "`echo -e "Have you finished installing the cv rpm,yes/no.default \e[1;33myes\e[0m: "`" RpmConfirm
			if [ "${RpmConfirm:=yes}" == "yes" ];then
				break
			elif [ "${RpmConfirm:=yes}" == "no" ];then
				continue
			else
				echo "You only enter value yes or no."
				continue
			fi 
			
		done
		while true
		do
			echo -e "\n\n\n\n" | ${ORACLE_HOME}/runcluvfy.sh stage -pre crsinst -n `sed -n '/^#public ip/,/^#private ip/p' /etc/hosts | egrep "^[[:digit:]]" | awk '{printf $2","}' | awk '{print substr($0,1,length($0)-1)}'`  -fixup -verbose > ~/gridcheck.txt
			echo -e "\e[1;33mPlease check the ~/gridcheck.txt to sure that everything is ok before installing grid.\e[0m: "
			read -p "`echo -e "\e[1;33mHave you checked the file and then go on installing grid,yes/no.\e[0m: "`" CheckFileConfirm
			if [ ${CheckFileConfirm:-null} == "null" ];then
				echo "You only enter the value, yes or no."
				continue
			elif [ ${CheckFileConfirm:-null} == "yes" ];then
				break
			elif [ ${CheckFileConfirm:-null} == "no" ];then
				continue
			else
				echo "You only enter the value, yes or no."
				continue
			fi
		done
		
		
	else
		echo "The Grid zip not find in grid home."
		exit 99
	fi
	
	
}


####################################################################################
#create grid rsp file
####################################################################################
CreateGirdRspFile(){
	####################################################################################
	#get scanname
	####################################################################################
	if [ ! ${scanname} ];then
		while true
		do
			read -p "`echo -e "please enter the name for scanName.default \e[1;33mracscan\e[0m: "`" scanname   #get scanname
			echo -e "Your scanNmae is \e[1;33m" ${scanname:=racscan}"\e[0m."
			read -p "`echo -e "please confirm the scanNmae -\e[1;33m${scanname}\e[0m-, yes/no,default \e[1;33myes\e[0m: "`" scanConfirm  #confirm scanmae
			if [ ${scanConfirm:=yes} == "yes" ];then
				break
			elif [ ${scanConfirm:=yes} == "no" ];then
				continue
			else
				echo "Please enter yes or no."
				continue
			fi
		done
	fi
	####################################################################################
	#get cluster name
	####################################################################################
	if [ ! ${clustername} ];then
		while true
		do
			read -p "`echo -e "please enter the name for clusterName.default \e[1;33mserver-cluster\e[0m: "`" clustername       #get cluster name
			echo -e "Your scanNmae is \e[1;33m" ${clustername:=server-cluster}"\e[0m."
			read -p "`echo -e "please confirm the clusterName  \e[1;33m${clustername}\e[0m , yes/no,default \e[1;33myes\e[0m: "`" clusterConfirm  #onfirm cluster name
			if [ ${clusterConfirm:=yes} == "yes" ];then
				break
			elif [ ${clusterConfirm:=yes} == "no" ];then
				continue
			else
				echo "Please enter yes or no."
				continue
			fi
		done
	fi
	####################################################################################
	#get hostname and hostname-vip
	####################################################################################
	if [ ! ${hostnames} ];then
		exhostnames="`hostname`:`hostname`-vip"
		while true
		do
			echo "please enter the whole nodes's hostname.And you use commas to separated the multiple groups of names。"
			read -p "`echo -e "Example: \e[1;33 ${exhostnames} \e[0m: "`" hostnames
			if [ ${hostnames} ];then
				echo -e "Your hostnames are \e[1;33m " ${hostnames} " \e[0m."
			else
				echo "\e[1;33The hostnames can be empty!!\e[0m"
				continue
			fi
			read -p "`echo -e "please confirm the hostnames \e[1;33m${hostnames}\e[0m , yes/no,default \e[1;33myes\e[0m: "`" hostConfirm
			if [ ${hostConfirm:=yes} == "yes" ];then
				break
			elif [ ${hostConfirm:=yes} == "no" ];then
				continue
			else
				echo "Please enter yes or no."
				continue
			fi
		done
	fi


	####################################################################################
	#get IP Management style
	####################################################################################
	while true
	do
		echo ""
		echo "Enter a number for the specified interface to bind to how the network card is managed."
		echo "InterfaceType stand for the following values"
		echo -e "\e[1;33m   - 1 : PUBLIC\e[0m"
		echo -e "\e[1;33m   - 2 : PRIVATE\e[0m"
		echo -e "\e[1;33m   - 3 : DO NOT USE\e[0m"
		echo -e "\e[1;33m   - 4 : ASM\e[0m"
		echo -e "\e[1;33m   - 5 : ASM & PRIVATE\e[0m"
		unset NetworkMS #clear variable NetworkMS
		for i in `ip addr | egrep "^[2-9]" | awk -F ':' '{print $2}'`  #circuate the interface name
		do
			IPTemp=`/usr/sbin/ifconfig $i | egrep "broadcast|netmaskt" | awk '{print $2}' | sed ':label;N;s/\n//;b label' | sed -e 's/ //g' -e 's/)//g'`   #get IP of the interface 
			BroadTemp=`/usr/sbin/ifconfig $i | egrep "broadcast|netmaskt" | awk '{print $4}' | sed ':label;N;s/\n//;b label' | sed -e 's/ //g' -e 's/)//g'`  ##get broadcast of the interface 
			[ ${BroadTemp} ] || break   #if the broadcast is null then break 
			NetworkTemp=$(ipcalc -n  ${IPTemp} ${BroadTemp} | awk -F"=" '{print $2}')  #get network order ot ip and broadcast
    	    #get interface:network:networkManagement
			while true
			do
				
    	    	NetworkMSTemp=""
    	    	printf "%10s : %-20s: " $i ${NetworkTemp}  #show the interface:network
    	    	read -p "" NetworkMSTemp  #get networkManagement
    	    	#Determine if the input is a number
    	    	if [[ `grep '^[[:digit:]]*$' <<< "${NetworkMSTemp}"` ]] && [[ ${NetworkMSTemp} -le 5 ]];then
    	    		break 
    	    	else
    	    		echo "You must enter a number and the number less than 5！" 
    	    		continue
    	    	fi
			done
			#get the whole interface:network:networkManagement
			[ ${NetworkMS} ] && NetworkMS=`echo ${NetworkMS}","$i":"${NetworkTemp}":"${NetworkMSTemp}` || NetworkMS=`echo $i":"${NetworkTemp}":"${NetworkMSTemp}`
		done
		echo ""
		echo "Your interface management list:"
		NetworkMSArray=(${NetworkMS//,/ })
		for var in ${NetworkMSArray[@]}
		do
   			echo ${var} | awk -F":" '{if($3==1) {printf "    "$1":"$2":PUBLIC\n"} else if($3==2){printf "    "$1":"$2":PRIVATE\n"}else if($3==3){printf "    "$1":"$2":DO NOT USE\n"}else if($3==4){printf "    "$1":"$2":ASM\n"}else if($3==5){printf "    "$1":"$2":ASM & PRIVATE\n"}}'
   		done
   		#confirm the interfaces management
   		while true
   		do
   			read -p "`echo -e "please confirm the interface management, yes/no,default \e[1;33myes\e[0m: "`" interfaceConfirm
   			if [ ${interfaceConfirm:=yes} == "yes" ];then
   				break
   				
   			elif [ ${interfaceConfirm:=yes} == "no" ];then
   				break
   			else
   				echo "You must yes or no."
   				continue
   			fi
   		done
   		[ ${interfaceConfirm} == "yes" ] && break || continue
 
	done
	
	
	####################################################################################
	#get diskgroup name,redundancy,path
	####################################################################################
	
	#disk discovery path
	while true
	do
		echo ""
		echo "Default disks discovery path is /dev/sd*.Do you wang to change?"
		read -p "`echo -e "yes/no,Default \e[1;33mno\e[0m: "`" DefDiskPathConfirm
		if [ "${DefDiskPathConfirm:=no}" == "yes" ];then
			read -p "`echo -e "Please enter the new disks path : "`" DiskPath
			if [ `ls -lh ${DiskPath:=""} 2>/dev/null  | awk '/grid asmadmin/{print $0}' | wc -l ` -ge 1 ];then
				echo ""
				echo -e "\e[1;33mAvaliable disk list:\e[0m"
				ls -lh ${DiskPath:=""} 2>/dev/null  | awk '/grid asmadmin/{print "	"$NF}'
				#ls -lh ${DiskPath:=""} 2>/dev/null  | awk '/grid asmadmin/{print '${DiskPath}'$0}'
				break 
			#else
			#	echo "You must enter a exists path!"
			#	continue
			fi
			
		elif [ "${DefDiskPathConfirm:=no}" == "no" ];then
			DiskPath='/dev/sd*'
			echo ""
			echo -e "\e[1;33mAvaliable disk list:\e[0m"
			ls -lh ${DiskPath:='/dev/sd*'} 2>/dev/null  | awk '/grid asmadmin/{print "	"$NF}'
			break
		
		else
			echo "You only enter yes or no,please enter right value."
			continue
		fi
	done
	
	#diskgroup name
	while true
	do
		echo ""
		echo -e "\e[1;33mOCR and Voting disk data will be stored in the following ASM Disk group.\e[0m"
		read -p "`echo -e "Disk group name.Default\e[1;33m OCR01 \e[0m: "`" ASMdgn
		read -p "`echo -e "Disk group redundancy,EXTERNAL/NORMAL/HIGH.Default \e[1;33m EXTERNAL \e[0m: "`" ASMRedundancy
		read -p "`echo -e "Enter disks for disk group.Multiple paths are separated by commas.: "`" ASMdisks
		if [ ! ${ASMdisks} ];then
			echo "The disks can not be empty!!"
			continue
		fi
		if [[ ${ASMRedundancy:="EXTERNAL"} == "NORMAL" ]] || [[ ${ASMRedundancy:="EXTERNAL"} == "HIGH" ]];then
			ASMDiskArray=(${ASMdisks//,/ })
			for var in ${ASMDiskArray[@]}
			do
				while true
				do
					read -p "`echo -e "Enter Failuregroup for ${var}: "`" ASMFGTmp
					if [ ${ASMFGTmp} ];then
						#ASMFGs=${ASMFGs}${ASMFGTmp}","
						#ASMFGsWithDisks=${ASMFGsWithDisks}","${var}","${ASMFGTmp}
						if [ ! ${ASMFGs} ];then
							ASMFGs=${ASMFGTmp}","
							ASMFGsWithDisks=${var}","${ASMFGTmp}
						else
							ASMFGs=${ASMFGs}${ASMFGTmp}","
							ASMFGsWithDisks=${ASMFGsWithDisks}","${var}","${ASMFGTmp}
						fi
						break
					else
						echo "The ASM failuregroup can be empty!"
						continue
					fi
					unset ASMFGTmp
				done
				
			
			done
		else
			ASMFGsWithDisks=`echo ${ASMdisks} | awk -F',' '{for(i=1;i<=NF;i++){if(i!=NF){printf $i",,"}else{print $i","}}}'`
		fi
		echo ""
		echo -e "\e[1;33mDisk group name is \e[1;33m${ASMdgn:=OCR01}.\e[0m"
		echo -e "\e[1;33mDisk group redundancy is \e[1;33m${ASMRedundancy}.\e[0m"
		echo -e "\e[1;33mThe disks of diskgroup are \e[1;33m${ASMdisks}.\e[0m"
		if [ ${ASMFGs} ];then
			echo -e "\e[1;33mThe disks with failuregroup are :\e[0m"
			echo ${ASMFGsWithDisks} | awk -F',' '{for(i=1;i<=NF;i++){{if(i%2==0) {printf $i"\n"} else {printf "	"$i":"}}}}'
		fi
		
		while true
		do
			read -p "`echo -e "Do you want to change the diskgroup infomations,yes/no.default \e[1;33mno\e[0m: "`" ASMConfirm
			if [ "${ASMConfirm:=no}" == "yes" ];then
				break
			elif [ "${ASMConfirm:=no}" == "no" ];then
				break
			else
				echo "You must enter yes or no."
				continue
			fi
		done
		[ "${ASMConfirm:=no}" == "yes" ] && continue || break
	done
	
	
}


####################################################################################
#install grid function
####################################################################################
InstallGrid(){
	#${ORACLE_HOME}/gridSetup.sh -silent -ignorePrereqFailure -responseFile ~/grid.rsp -waitForCompletion
	if [ ${ASMFGs} ];then
		GridInstallString="INVENTORY_LOCATION=/u01/app/grid/oraInventory
		 SELECTED_LANGUAGES=en,en_GB 
 oracle.install.option=CRS_CONFIG 
 ORACLE_BASE=/u01/app/grid 
 oracle.install.asm.OSDBA=asmdba 
 oracle.install.asm.OSASM=asmadmin 
 oracle.install.asm.OSOPER=asmoper  
 oracle.install.crs.config.scanType=LOCAL_SCAN 
 oracle.install.crs.config.gpnp.scanName=${scanname} 
 oracle.install.crs.config.gpnp.scanPort=1521 
 oracle.install.crs.config.ClusterConfiguration=STANDALONE 
 oracle.install.crs.config.configureAsExtendedCluster=false 
 oracle.install.crs.config.clusterName=${clustername} 
 oracle.install.crs.config.gpnp.configureGNS=false 
 oracle.install.crs.config.autoConfigureClusterNodeVIP=false 
 oracle.install.crs.config.clusterNodes=${hostnames} 
 oracle.install.crs.config.networkInterfaceList=${NetworkMS} 
 oracle.install.asm.configureGIMRDataDG=false 
 oracle.install.crs.config.useIPMI=false 
 oracle.install.asm.storageOption=FLEX_ASM_STORAGE 
 oracle.install.asmOnNAS.configureGIMRDataDG=false 
 oracle.install.asm.SYSASMPassword=oracle 
 oracle.install.asm.diskGroup.name=${ASMdgn} 
 oracle.install.asm.diskGroup.redundancy=${ASMRedundancy} 
 oracle.install.asm.diskGroup.AUSize=4 
 oracle.install.asm.diskGroup.FailureGroups=${ASMFGs} 
 oracle.install.asm.diskGroup.disksWithFailureGroupNames=${ASMFGsWithDisks}  
 oracle.install.asm.diskGroup.disks=${ASMdisks} 
 oracle.install.asm.diskGroup.diskDiscoveryString=${DiskPath}
 oracle.install.asm.configureAFD=false 
 oracle.install.asm.monitorPassword=oracle 
 oracle.install.crs.configureRHPS=false 
 oracle.install.crs.config.ignoreDownNodes=false 
 oracle.install.config.managementOption=NONE 
 oracle.install.config.omsPort=0 
 oracle.install.crs.rootconfig.executeRootScript=false"
	else
		GridInstallString="INVENTORY_LOCATION=/u01/app/grid/oraInventory 
 SELECTED_LANGUAGES=en,en_GB 
 oracle.install.option=CRS_CONFIG 
 ORACLE_BASE=/u01/app/grid 
 oracle.install.asm.OSDBA=asmdba 
 oracle.install.asm.OSASM=asmadmin 
 oracle.install.asm.OSOPER=asmoper  
 oracle.install.crs.config.scanType=LOCAL_SCAN 
 oracle.install.crs.config.gpnp.scanName=${scanname} 
 oracle.install.crs.config.gpnp.scanPort=1521 
 oracle.install.crs.config.ClusterConfiguration=STANDALONE 
 oracle.install.crs.config.configureAsExtendedCluster=false 
 oracle.install.crs.config.clusterName=${clustername} 
 oracle.install.crs.config.gpnp.configureGNS=false 
 oracle.install.crs.config.autoConfigureClusterNodeVIP=false 
 oracle.install.crs.config.clusterNodes=${hostnames} 
 oracle.install.crs.config.networkInterfaceList=${NetworkMS} 
 oracle.install.asm.configureGIMRDataDG=false 
 oracle.install.crs.config.useIPMI=false 
 oracle.install.asm.storageOption=FLEX_ASM_STORAGE 
 oracle.install.asmOnNAS.configureGIMRDataDG=false 
 oracle.install.asm.SYSASMPassword=oracle 
 oracle.install.asm.diskGroup.name=${ASMdgn} 
 oracle.install.asm.diskGroup.redundancy=${ASMRedundancy} 
 oracle.install.asm.diskGroup.AUSize=4 
 oracle.install.asm.diskGroup.disksWithFailureGroupNames=${ASMFGsWithDisks}  
 oracle.install.asm.diskGroup.disks=${ASMdisks} 
 oracle.install.asm.diskGroup.diskDiscoveryString=${DiskPath}
 oracle.install.asm.configureAFD=false 
 oracle.install.asm.monitorPassword=oracle 
 oracle.install.crs.configureRHPS=false 
 oracle.install.crs.config.ignoreDownNodes=false 
 oracle.install.config.managementOption=NONE 
 oracle.install.config.omsPort=0 
 oracle.install.crs.rootconfig.executeRootScript=false"
	fi
	#echo ${GridInstallString}
	
	####################################################################################
	#install grid 
	####################################################################################
	#echo "${ORACLE_HOME}/gridSetup.sh -ignorePrereq -waitforcompletion -silent -responseFile ${ORACLE_HOME}/install/response/gridsetup.rsp ${GridInstallString}"
	${ORACLE_HOME}/gridSetup.sh -ignorePrereq -waitforcompletion -silent -responseFile ${ORACLE_HOME}/install/response/gridsetup.rsp ${GridInstallString}
	
	echo -e "\e[1;31mAttention: You need not to execute configuration script.\e[0m"
	while true
	do
		read -p "`echo -e "Have you finished executing the script？yes/no: "`" ExecScriptCon
		if [ "${ExecScriptCon}" == "yes" ];then
			${ORACLE_HOME}/gridSetup.sh -silent -executeConfigTools  -waitforcompletion -responseFile ${ORACLE_HOME}/install/response/gridsetup.rsp ${GridInstallString}
			break
		elif [ "${ExecScriptCon}" == "no" ];then
			continue
		else
			echo "You must enter yes or no!"
			continue
		fi
	done


	
	
}

####################################################################################
#entrance of script
####################################################################################
CreateGirdRspFile
UnzipPRMAndCheck
InstallGrid





