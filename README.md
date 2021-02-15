# opatchauto_apply_giru

## confrict check (USER:grid,oracle)

ls -d /opt/media/RU/32226239/[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]|while read line;do $ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -phBaseDir ${line};done

## exec apply ru (USER:root)
cd /opt/media/RU;sh opatch_apply_ru.sh


# Workaround for the error that occurs when 30899722 is applied to node2
## copy inventory files from node1 (USER:grid)
scp -r node1:/u01/app/19.0.0/grid/inventory/oneoffs/308* /u01/app/19.0.0/grid/inventory/oneoffs/
## change owner (USER:root)
chown grid /u01/app/oraInventory/ContentsXML/oui-patch.xml
## change permission (USER:root)
chmod 660 /u01/app/oraInventory/ContentsXML/oui-patch.xml
## resume(USER:root)
/u01/app/19.0.0/grid/OPatch/opatchauto resume
