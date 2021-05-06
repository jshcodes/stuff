#!/bin/bash
if [ -z $1 ]
then
  echo "Usage: uninstall-sensor {InstanceId}"
else
  result=$(aws ssm send-command --document-name AWS-ConfigureAWSPackage --instance-ids $1 --parameters '{"action":["Uninstall"],"installationType":["Uninstall and reinstall"],"name":["'$PACKAGE_NAME'"]}' --region $REGION | jq .[].ErrorCount)
  if [[ "$result" == 0 ]]
  then
    echo "Falcon agent removal has been scheduled.  Please allow 2 minutes for uninstall to complete."
  else
    echo "An error occurred while scheduling the removal of the agent."
  fi
fi