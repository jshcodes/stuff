#!/bin/bash


help(){
    echo "You must specify the command that you wish to review. (ex: help agent-install)"
}

if [ -z "$1" ]
then
    help
else
    case "$1" in
        agent-install ) echo -e "\nSource code for $1\n"
            cat /usr/local/bin/$1
            ;;
        agent-uninstall ) echo -e "\nSource code for $1\n"
            cat /usr/local/bin/$1
            ;;
        connect ) echo -e "\nSource code for $1"
            cat /usr/local/bin/$1
            ;;
        list-agents ) echo -e "\nSource code for agent-list.py\n"
            cat /usr/local/bin/agent-list.py
            ;;
        list-instances ) echo -e "\nSource code for $1\n"
            cat /usr/local/bin/$1
            ;;
        local-agent-install ) echo -e "\nSource code for $1\n"
            cat /usr/local/bin/$1
            ;;
        local-agent-uninstall ) echo -e "\nSource code for $1\n"
            cat /usr/local/bin/$1
            ;;
        show-code ) echo -e "\nSource code for $1\n"
            cat /usr/local/bin/$1
            ;;            
        \? ) echo "Stop mumbling!"
             help
             exit 1
             ;;
        help ) showHelp
               exit 0
               ;;
    esac
fi
