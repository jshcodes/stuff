#!/bin/bash
# CrowdStrike Falcon Agent bootstrap - CentOS / RHEL / Oracle

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
   if [[ "$var" == *--os=* ]]
   then
      OS_NAME="${var/--os=/}"
      PROCEED=$((PROCEED + 1))      
   fi         
   if [[ "$var" == *--osver=* ]]
   then
      OS_VERSION="${var/--osver=/}"
   fi   
done

if [[ $PROCEED -eq 4 ]]
then
   cd /var/tmp
   curl -o get-sensor https://raw.githubusercontent.com/jshcodes/stuff/main/cssensor_download.sh
   chmod 755 get-sensor
   export CS_FALCON_CLIENT_ID=$CLIENT_ID
   export CS_FALCON_CLIENT_SECRET=$CLIENT_SECRET
   ./get-sensor $OS_NAME $OS_VERSION .
   rpm -ivh sensor.rpm
   /opt/CrowdStrike/falconctl -s -f --cid=$CLIENT_CID
   systemctl restart falcon-sensor
   rm get-sensor
   rm sensor.rpm
else
   echo "Invalid attributes. Check syntax and try again."
   echo "csfalcon-bootstrap-centos.sh --client_id=(CLIENT_ID) --client_secret=(CLIENT_SECRET) --cid=(CID) --os=(OS_NAME) { --osver=(OS_VERSION) }"
fi

exit




