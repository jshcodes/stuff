#!/bin/bash

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

# export CS_FALCON_CLIENT_ID=$CLIENT_ID
# export CS_FALCON_CLIENT_SECRET=$CLIENT_SECRET

OS_NAME=$(cat /etc/*release | grep NAME= | awk '{ print $1 }' | awk -F'=' '{ print $2 }' | sed "s/\"//g")
OS_NAME=$(echo $OS_NAME | awk '{ print $1 }')
OS_VERSION=$(cat /etc/*release | grep VERSION_ID= | awk '{ print $1 }' | awk -F'=' '{ print $2 }' | sed "s/\"//g")

if [[ $PROCEED -eq 3 ]]
then
    case "$OS_NAME" in
        SLES )
            cd /var/tmp
            curl -o csfalcon_bootstrap https://raw.githubusercontent.com/jshcodes/stuff/main/csfalcon-bootstrap-sles.sh
            chmod 755 csfalcon_bootstrap
            if [[ "$OS_VERSION" == *11* ]]
            then
                ./csfalcon_bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=sles --osver=11
            elif [[ "$OS_VERSION" == *12* ]]
            then
                ./csfalcon_bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=sles --osver=12
            else
                ./csfalcon_bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=sles --osver=15
            fi
            ;;
        Amazon )
            cd /var/tmp
            wget -O csfalcon_bootstrap https://raw.githubusercontent.com/jshcodes/stuff/main/csfalcon-bootstrap-amzn-lnx2.sh
            chmod 755 csfalcon_bootstrap
            #TODO: Add arm detection
            ./csfalcon_bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=amzn --osver=2
            ;;

        CentOS )
            cd /var/tmp
            curl -o csfalcon_bootstrap https://raw.githubusercontent.com/jshcodes/stuff/main/csfalcon-bootstrap-centos.sh
            chmod 755 csfalcon_bootstrap
            if [[ "$OS_VERSION" == *7* ]]
            then
                ./csfalcon_bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=centos --osver=7
            fi
            ;;

        RHEL )
            cd /var/tmp
            curl -o csfalcon_bootstrap https://raw.githubusercontent.com/jshcodes/stuff/main/csfalcon-bootstrap-centos.sh
            chmod 755 csfalcon_bootstrap
            if [[ "$OS_VERSION" == *7* ]]
            then
                ./csfalcon_bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=rhel --osver=7
            elif [[ "$OS_VERSION" == *6* ]]
            then
                ./csfalcon_bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=rhel --osver=6
            else
                ./csfalcon_bootstrap --client_id=$CLIENT_ID --client_secret=$CLIENT_SECRET --cid=$CLIENT_CID --os=rhel --osver=8
            fi
            ;;

    esac
    rm csfalcon_bootstrap
fi