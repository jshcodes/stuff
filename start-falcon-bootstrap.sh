#!/bin/bash

CLIENT_ID=""
CLIENT_SECRET=""
CLIENT_CID=""
OS_NAME=""
OS_VERSION=""
PROCEED=0
for var in $*; do 
   if [[ "$var" == *--client_id=* ]]
   then
      CLIENT_ID="${var/--client_id=/}"
      PROCEED=$((PROCEED + 1))
   fi   
   if [[ "$var" == *--client_secret=* ]]
   then
      CLIENT_SECRET="${var/--client_secret=/}"
      PROCEED=$((PROCEED + 1))      
   fi   
   if [[ "$var" == *--cid=* ]]
   then
      CLIENT_CID="${var/--cid=/}"
      PROCEED=$((PROCEED + 1))      
   fi   
done


RELEASE=$(cat /etc/*release)
OS_NAME=$(echo $RELEASE | awk '{ print $1 }' | awk -F'=' '{ print $2 }' | sed "s/\"//g")
OS_VERSION=$(echo $RELEASE | awk '{ print $1 }' | awk -F'=' '{ print $2 }' | sed "s/\"//g")

if [[ $PROCEED -eq 3 ]]
then
    case "$OS_NAME" in
        SLES )
            cd /var/tmp
            curl -o bootstrap https://raw.githubusercontent.com/jshcodes/stuff/main/csfalcon-bootstrap-sles.sh
            chmod 755 bootstrap
            if [[ "$OS_VERSION" == *12* ]]
            then
                ./bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=sles --osver=12
            else
                ./bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=sles --osver=15
            fi
            ;;

    esac
    rm bootstrap
fi