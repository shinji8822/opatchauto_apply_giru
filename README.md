# opatchauto_apply_giru

## confrict check (USER:grid,oracle)

ls -d /opt/media/RU/32226239/[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]|while read line;do $ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -phBaseDir ${line};done

## exec apply ru (USER:root)
cd /opt/media/RU;sh opatch_apply_ru.sh
