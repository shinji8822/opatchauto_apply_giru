#!/bin/bash

source ./opatch_latest_version.txt
source ./giru_version.txt
GI_HOME=/u01/app/19.0.0/grid
DB_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
NODE1=192.168.56.101
NODE2=192.168.56.102
GIUSER=grid
DBUSER=oracle
WORKDIR=/opt/media

#GI_OP_VER=$(ssh grid@${NODE1}  ${GI_HOME}/OPatch/opatch version|grep "OPatch Version:"|awk -F': ' '{print $2}')
#echo $GI_OP_VER
#DB_OP_VER=$(ssh oracle@${NODE1}  ${DB_HOME}/OPatch/opatch version|grep "OPatch Version:"|awk -F': ' '{print $2}')
#echo $DB_OP_VER


get_op_ver () {
	ssh ${1}@${2} ${3}/OPatch/opatch version|grep "OPatch Version:"|awk -F': ' '{print $2}'
}

upd_op () {
	[ "${1}" == "grid" ] &&	ssh root@${2} chmod g+w ${3}
	ssh ${1}@${2} mv ${3}/OPatch ${3}/OPatch_${4}
	ssh ${1}@${2} unzip -q ${WORKDIR}/RU/OPatch/${opatch_latest_version}/p6880880*Linux-x86-64.zip -d ${3}
	[ "${1}" == "grid" ] && ssh root@${2} chmod g-w ${3}
}

unzip_ru () {
	[ ! -e ${WORKDIR}/RU/${GIRU} ] && ssh grid@${1} unzip -q ${WORKDIR}/RU/p${GIRU}*zip -d ${WORKDIR}/RU
}

apply_ru () {
	ssh root@${1} ${GI_HOME}/OPatch/opatchauto apply ${WORKDIR}/RU/${GIRU}
}

# Upgrade OPatch Module
for node in ${NODE1} ${NODE2};do
	for user in ${GIUSER} ${DBUSER};do
		[ "${user}" == "grid" ] && TARGET_HOME=${GI_HOME}
		[ "${user}" == "oracle" ] && TARGET_HOME=${DB_HOME}
		OP_VER_BEFORE=$(get_op_ver ${user} ${node} ${TARGET_HOME})
		if [ "${OP_VER_BEFORE}" != "$opatch_latest_version" ]; then
			upd_op ${user} ${node} ${TARGET_HOME} ${OP_VER_BEFORE}	
		else
			echo "Skipped updating OPatch."
		fi

	done
done

# Unzip RU Zipfile
unzip_ru ${NODE1}

# ApplyRU
#for node in ${NODE1} ${NODE2};do
#	for user in ${GIUSER} ${DBUSER};do
#		apply_ru ${node} 		
#	done
#done
