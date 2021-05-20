#!/bin/bash

if ! [[ -z $1 ]]
then
    ACTION=$1
else
    ACTION="help"
fi

if [[ "$ACTION" == "help" ]]
then
    echo "connect {target}"
    echo "Available targets: linux, windows"
elif [[ "$ACTION" == "linux" ]]
then
    ssh -i $SSHKEY -o StrictHostKeyChecking=no ec2-user@$LINUX_1 $2 $3 $4
elif [[ "$ACTION" == "linux1" ]]
then
    ssh -i $SSHKEY -o StrictHostKeyChecking=no ec2-user@$LINUX_1 $2 $3 $4
elif [[ "$ACTION" == "windows" ]]
then
    aws ssm start-session --target $WINDOWS_1
elif [[ "$ACTION" == "win1" ]]
then
    aws ssm start-session --target $WINDOWS_1
else
    echo "Invalid target specified."
fi