#!/bin/bash

cd `dirname $0`
source ./logging.sh

prepare(){
    sh prepare_check.sh
    if [ $? != 0 ]
    then
        ora_log "preOpt Failed"
        exit 1
    fi
    sh prepare.sh
}
grid_install(){
    sh grid_install.sh
}
grid_uninstall(){
    sh grid_uninstall.sh
}
asmca_install(){
    sh asmca_install.sh
}
asmca_uninstall(){
    sh asmca_uninstall.sh
}
db_install(){
    bash  db_install.sh
}
db_uninstall(){
    sh db_uninstall.sh
}
dbca_install(){
    sh dbca_install.sh
}
dbca_uninstall(){
    sh dbca_uninstall.sh
}
rac_usage(){
   sh rac_usage
}

smart_uninstall(){
    sh force_uninstall.sh    
}

opt=$1
shift
case $opt in 
    -preOpt)
        prepare
        ;;
    -grid)
        grid_install
    ;;
    -un_grid)
        grid_uninstall
    ;;
    -asmca)
        asmca_install
    ;;
    -un_asmca)
        asmca_uninstall
    ;;
    -dbInstall)
        db_install
    ;;
    -un_db)
        db_uninstall
    ;;
    -dbca)
        dbca_install
    ;;
    -un_dbca)
        dbca_uninstall
    ;;
    -all)
        ora_log "############ STAGE 1 -preOpt ############"
        prepare       || { echo "[ERROR] -preOpt fail" ; exit 1 ;}
        ora_log "############ STAGE 2 -grid   ############"
        grid_install  || { echo "[ERROR] -grid fail" ; exit 1; }
        ora_log "############ STAGE 3 -asmca  ############"
        asmca_install || { echo "[ERROR] -asmca fail" ; exit 1; }
        ora_log "############ STAGE 4 -db     ############"
        db_install    || { echo "[ERROR] -db fail" ; exit 1 ; }
        ora_log "############ STAGE 5 -dbca   ############"
        dbca_install  || { echo "[ERROR] -dbca fail" ;  exit 1 ; }
        ora_log "############ ALL END ############"
    ;;
    -uninstall)
        smart_uninstall
    ;;
    *)
    rac_usage
    ;;
esac
