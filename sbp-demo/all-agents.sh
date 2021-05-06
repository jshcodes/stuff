#!/bin/bash
if [ -z "$1" ]
then
    echo "Usage: all-agents {install|uninstall}"
    exit 1
fi
if [[ "$1" == "install" ]]
then
    MODE="Install"
elif [[ "$1" == "uninstall" ]]
then
    MODE="Uninstall"
else
    echo "Unrecognized command"
    echo "Usage: all-agents {install|uninstall}"
    exit 1
fi
for i in $(instance-list); do
  result=$(aws ssm send-command --document-name AWS-ConfigureAWSPackage --instance-ids $i --parameters '{"action":["'$MODE'"],"installationType":["Uninstall and reinstall"],"name":["'$PACKAGE_NAME'"]}' --region $REGION | jq .[].ErrorCount)
  if [[ "$result" == 0 ]]
  then
    echo "Falcon agent installation has been scheduled.  Please allow 2 minutes for install to complete."
  else
    echo "An error occurred while scheduling the installation of the agent."
  fi
done