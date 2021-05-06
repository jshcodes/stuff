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
    echo "Available targets: linux1, linux2, windows1, windows2"
elif [[ "$ACTION" == "linux1" ]]
then
    ssh -i $SSHKEY -o StrictHostKeyChecking=no ec2-user@$LINUX_1 $2 $3 $4
elif [[ "$ACTION" == "linux2" ]]
then
    ssh -i $SSHKEY -o StrictHostKeyChecking=no ec2-user@$LINUX_2 $2 $3 $4
elif [[ "$ACTION" == "win1" ]]
then
    aws ssm start-session --target $WINDOWS_1
elif [[ "$ACTION" == "win2" ]]
then
    aws ssm start-session --target $WINDOWS_2
else
    echo "Invalid target specified."
fi