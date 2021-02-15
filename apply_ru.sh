#!/bin/bash

source ./opatch_latest_version.txt
source ./giru_version.txt
GI_HOME=/u01/app/19.0.0/grid
DB_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
NODE1=192.168.56.101
NODE2=192.168.56.102
GIUSER=grid
DBUSER=oracle
WORKDIR=/opt/media/RU

#GI_OP_VER=$(ssh grid@${NODE1}  ${GI_HOME}/OPatch/opatch version|grep "OPatch Version:"|awk -F': ' '{print $2}')
#echo $GI_OP_VER
#DB_OP_VER=$(ssh oracle@${NODE1}  ${DB_HOME}/OPatch/opatch version|grep "OPatch Version:"|awk -F': ' '{print $2}')
#echo $DB_OP_VER


get_op_ver () {
        ssh ${1}@${2} ${3}/OPatch/opatch version|grep "OPatch Version:"|awk -F': ' '{print $2}'
}

upd_op () {
        [ "${1}" == "grid" ] && ssh root@${2} chmod g+w ${3}
        ssh ${1}@${2} mv ${3}/OPatch ${3}/OPatch_${4}
        ssh ${1}@${2} unzip -q ${WORKDIR}/OPatch/${opatch_latest_version}/p6880880*Linux-x86-64.zip -d ${3}
        [ "${1}" == "grid" ] && ssh root@${2} chmod g-w ${3}
}

unzip_ru () {
        ssh grid@${1} [ ! -d ${WORKDIR}/${GIRU} ] && ssh grid@${1} unzip -q -o ${WORKDIR}/p${GIRU}*zip -d ${WORKDIR}
}

systemspace_check () {
        ssh ${1}@${2} rm -f ${WORKDIR}/patch_list_gihome.txt ${WORKDIR}/systemspace_result.txt
        ssh ${1}@${2} ls -d ${WORKDIR}/${GIRU}/[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] \> ${WORKDIR}/patch_list_gihome.txt
        ssh ${1}@${2} ${GI_HOME}/OPatch/opatch prereq CheckSystemSpace -phBaseFile ${WORKDIR}/patch_list_gihome.txt \> ${WORKDIR}/systemspace_result.txt
        ssh ${1}@${2} grep checkSystemSpace ${WORKDIR}/systemspace_result.txt \|awk '{print\ \$3}'
}

apply_ru () {
        ssh root@${1} ${GI_HOME}/OPatch/opatchauto apply ${WORKDIR}/${GIRU}|tee -a ${WORKDIR}/apply_ru_$(hostname -s)_$(date +%Y%m%d_%H%M%S).log
        echo $?
}

# Upgrade OPatch Module
echo $(date "+%Y-%m-%dT%H:%M:%S") : Starting Upgrade OPatch Module.
for node in ${NODE1} ${NODE2};do
        for user in ${GIUSER} ${DBUSER};do
                [ "${user}" == "grid" ] && TARGET_HOME=${GI_HOME}
                [ "${user}" == "oracle" ] && TARGET_HOME=${DB_HOME}
                echo ${node} / ${user} / ${TARGET_HOME}
                OP_VER_BEFORE=$(get_op_ver ${user} ${node} ${TARGET_HOME})
                if [ "${OP_VER_BEFORE}" != "$opatch_latest_version" ]; then
                        upd_op ${user} ${node} ${TARGET_HOME} ${OP_VER_BEFORE}
                else
                        echo "Skipped updating OPatch."
                fi

        done
done
echo $(date "+%Y-%m-%dT%H:%M:%S") : Finished Upgrade OPatch Module.

# Unzip RU Zipfile
echo $(date "+%Y-%m-%dT%H:%M:%S") : Starting Unzip RU Zipfile.
unzip_ru ${NODE1}
echo $(date "+%Y-%m-%dT%H:%M:%S") : Finished Unzip RU Zipfile.

# SystemSpace Check
echo $(date "+%Y-%m-%dT%H:%M:%S") : Starting SystemSpace Check.
for node in ${NODE1} ${NODE2};do
        for user in ${GIUSER};do
                result=$(systemspace_check ${user} ${node})
                [ "$result" == "passed." ] || exit 1
        done
done
echo $(date "+%Y-%m-%dT%H:%M:%S") : Finished SystemSpace Check.

# ApplyRU
echo $(date "+%Y-%m-%dT%H:%M:%S") : Starting ApplyRU.
for node in ${NODE1} ${NODE2};do
        echo ${node}
        result=$(apply_ru ${node})
        [ "$result" != "0" ] && echo "OK"|| echo "NG"
done
echo $(date "+%Y-%m-%dT%H:%M:%S") : Finished ApplyRU.
