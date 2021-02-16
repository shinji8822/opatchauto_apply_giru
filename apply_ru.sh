#!/bin/bash

source ./opatch_latest_version.txt
source ./giru_version.txt
source ./functions
source ./envs.txt

# Upgrade OPatch Module
echo $(date "+%Y-%m-%dT%H:%M:%S") : Starting Upgrade OPatch Module.
for node in ${NODE1} ${NODE2};do
        for user in ${GIUSER} ${DBUSER};do
                [ "${user}" == "grid" ] && TARGET_HOME=${GI_HOME}
                [ "${user}" == "oracle" ] && TARGET_HOME=${DB_HOME}
                echo "   ${user}@${node}, ORACLE_HOME=${TARGET_HOME}"
                OP_VER_BEFORE=$(get_op_ver ${user} ${node} ${TARGET_HOME})
                if [ "${OP_VER_BEFORE}" != "$opatch_latest_version" ]; then
                        upd_op ${user} ${node} ${TARGET_HOME} ${OP_VER_BEFORE}
                        echo "      => OPatch Module Updated, OPatch Version is ${OP_VER_BEFORE}."
                else
                        echo "      => Already OPatch Version is ${OP_VER_BEFORE}, Skipped updating OPatch."
                fi

        done
done
echo $(date "+%Y-%m-%dT%H:%M:%S") : Finished Upgrade OPatch Module.

# Unzip RU Zipfile
echo $(date "+%Y-%m-%dT%H:%M:%S") : Starting Unzip RU Zipfile.
result=$(unzip_ru ${NODE1})
[ "$result" == "0" ] || echo "   Patch has already been unzipped."
echo $(date "+%Y-%m-%dT%H:%M:%S") : Finished Unzip RU Zipfile.

# SystemSpace Check
echo $(date "+%Y-%m-%dT%H:%M:%S") : Starting SystemSpace Check.
for node in ${NODE1} ${NODE2};do
        for user in ${GIUSER};do
                result=$(systemspace_check ${user} ${node} ${GIRU} ${GI_HOME} ${WORKDIR})
                if [ "$result" == "passed." ]; then
                   echo "   ${node} is OK."
                else
                   echo "   ${node} is No space left on disk."
                   exit 1
                fi
        done
done
echo $(date "+%Y-%m-%dT%H:%M:%S") : Finished SystemSpace Check.

# ApplyRU
echo $(date "+%Y-%m-%dT%H:%M:%S") : Starting ApplyRU.
for node in ${NODE1} ${NODE2};do
        echo "   Patching ${node}." 
        result=$(apply_ru ${node})
        if [ "$result" == "0" ]; then
           echo "${node} is OK."
        else
           echo "${node} is NG."
           exit 1
        fi
done
echo $(date "+%Y-%m-%dT%H:%M:%S") : Finished ApplyRU.

