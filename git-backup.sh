#!/bin/bash

#--------------------------------------------------------------------------------
#                _   _                       _____ _           _           _ 
#     /\        | | | |                 _   / ____| |         | |         (_)
#    /  \  _   _| |_| |__   ___  _ __  (_) | (___ | |__   ___ | |__  _   _ _ 
#   / /\ \| | | | __| '_ \ / _ \| '__|      \___ \| '_ \ / _ \| '_ \| | | | |
#  / ____ \ |_| | |_| | | | (_) | |     _   ____) | | | | (_) | |_) | |_| | |
# /_/    \_\__,_|\__|_| |_|\___/|_|    (_) |_____/|_| |_|\___/|_.__/ \__,_| |
#                                                                        _/ |
#                                                                       |__/ 
#               __       _______ 
#|\     /|     /  \     (  __   )
#| )   ( |     \/) )    | (  )  |
#| |   | | _____ | |    | | /   |
#( (   ) )(_____)| |    | (/ /) |
# \ \_/ /        | |    |   / | |
#  \   /       __) (_ _ |  (__) |
#   \_/        \____/(_)(_______)
#                                
#-----------------------------------------------------------------------------------

scriptsBase=$(dirname "$0")
backupDir="$scriptsBase/git_backup"

credentialsConfig="$scriptsBase/git-credential.json"
if [ -f $credentialsConfig ]; then
	echo "Configuration File Found $credentialsConfig"
	username=$( cat $credentialsConfig | jq -r ".username" )
	usertoken=$(cat $credentialsConfig | jq -r ".password" )
else
	echo "Configuration file not found $credentialsConfig"
	exit 0
fi

echo "Username : $username , Usertoken : $usertoken"

mkdir -p $backupDir
if [ -d $backupDir ] ; then
        echo "Backup directory exists"
else
        echo "Backup directory does not exists"
	exit 0
fi

if [[ -z ${usertoken} ]]; then
	repoList=$( curl https://api.github.com/users/$username/repos | jq -r ".[].clone_url" )
else
	repoList=$( curl --header "Authorization: token $usertoken" https://api.github.com/user/repos | jq -r ".[].clone_url" )
fi

echo "Repolist"
echo "========================================================================"
while IFS= read -r repoUrl; do
	repoDir=$(echo $repoUrl | awk -F '/' '{ print $NF }' )
	cloneDir="${backupDir}/${repoDir}"
	echo "Repository Url: $repoUrl"
	echo "Clone Dir: $cloneDir"
	git clone $repoUrl $cloneDir
	echo "Pulling All Branches"
	cd $cloneDir/ && git pull --all
done <<< "$repoList"

