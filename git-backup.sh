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

reposCount=500
orgName='togetherGithub'
scriptsBase="$( cd "$( dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd )"
backupDir="$scriptsBase/git_backup"



gitApiUrl=""


credentialsConfig="$scriptsBase/git-credential.json"
if [ -f $credentialsConfig ]; then
	echo "$(date +"%Y-%m-%d %T") | Configuration File Found $credentialsConfig"
	username=$( cat $credentialsConfig | jq -r ".username" )
	usertoken=$(cat $credentialsConfig | jq -r ".password" )
else
	echo "$(date +"%Y-%m-%d %T") | ERROR : Configuration file not found $credentialsConfig"
	exit 1
fi

if [[ $orgName == '' ]]; then
	echo "$(date +"%Y-%m-%d %T") | User Repository"
        gitApiUrl="https://api.github.com/users/$username/repos"
else
	echo "$(date +"%Y-%m-%d %T") | Organization Repository"
        gitApiUrl="https://api.github.com/orgs/$orgName/repos"
fi

if [[ $gitApiUrl == '' ]]; then
	echo "$(date +"%Y-%m-%d %T") | ERROR : GitHub Api Url Empty. Exiting Program!"
	exit 1
fi


#echo "Username : $username , Usertoken : $usertoken"

mkdir -p $backupDir

if [ -d $backupDir ] ; then
        echo "$(date +"%Y-%m-%d %T") | Backup directory exists"
else
        echo "$(date +"%Y-%m-%d %T") | ERROR : Backup directory does not exists"
	exit 0
fi

if [[ -z ${usertoken} ]]; then
	echo "$(date +"%Y-%m-%d %T") | Getting Public Repository List"
	repoList=$( curl $gitApiUrl | jq -r ".[].clone_url" )
else
	echo "$(date +"%Y-%m-%d %T") | Getting All Repository List"
	repoList=$( curl --header "Authorization: token $usertoken" ${gitApiUrl}?per_page=$reposCount | jq -r ".[].clone_url" )
fi

echo "$(date +"%Y-%m-%d %T") | Repolist"
echo "========================================================================"
updatedCount=0
createdCount=0
while IFS= read -r repoUrl; do
	cd $backupDir
	repoDir=$(echo $repoUrl | awk -F '/' '{ print $NF }' )
	if [[ ! -z ${usertoken} ]]; then
		repoUrl=$(echo "${repoUrl/https\:\/\//https://$username:$usertoken@}")
	fi
	cloneDir="${backupDir}/${repoDir}"
	echo "$(date +"%Y-%m-%d %T") | Repository Url: $repoUrl"
	echo "$(date +"%Y-%m-%d %T") | Clone Dir: $cloneDir"
	if [[ -d $cloneDir ]]; then
		echo "$(date +"%Y-%m-%d %T") | Existing Local Repository! Getting Updates >>>"
		cd $cloneDir/ && git fetch --all
		((updatedCount++))
	else
		echo "$(date +"%Y-%m-%d %T") | New Local Repository! Cloning from remote >>>"
		git clone $repoUrl $cloneDir
	        echo "$(date +"%Y-%m-%d %T") | Pulling All Branches"
		((createdCount++))
	fi

	$branchList=$(cd $cloneDir && git branch -r)
        if [ -z $(cd $cloneDir && git branch -r) ]; then
		echo "No Remote Branch Found "
		exit 0
	else
		echo "Branch Found. Pulling all Branches"
		cd $cloneDir/ && git pull --all
        fi


done <<< "$repoList"


echo "$(date +"%Y-%m-%d %T") | Total Updated: $updatedCount"
echo "$(date +"%Y-%m-%d %T") | Total New: $createdCount"
echo "$(date +"%Y-%m-%d %T") | Completed"
