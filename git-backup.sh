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
scriptsBase="$( cd "$( dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd )"
backupDir="$scriptsBase/git_backup"
orgName=''
userRepoName=''


gitApiUrl=""

isOrganization=$1

# Get Github Credentials and Configurations
credentialsConfig="$scriptsBase/git-credential.json"
if [ -f $credentialsConfig ]; then
	echo "$(date +"%Y-%m-%d %T") | Configuration File Found $credentialsConfig"
	username=$( cat $credentialsConfig | jq -r ".username" )
	usertoken=$(cat $credentialsConfig | jq -r ".password" )
	orgName=$(cat $credentialsConfig | jq -r ".orgname")
	userRepoName=$(cat $credentialsConfig | jq -r ".userreponame")
else
	echo "$(date +"%Y-%m-%d %T") | ERROR : Configuration file not found $credentialsConfig"
	exit 1
fi

# If Shell Parameter passed is 1 then try pulling organization repository. Else try pulling user repository
if [[ $isOrganization -eq 1 ]]; then
	echo "$(date +"%Y-%m-%d %T") | Configuring Organization Repository URL"
	if [[ "$orgName" != "" ]]; then
		echo "$(date +"%Y-%m-%d %T") | Organization Repository"
	        gitApiUrl="https://api.github.com/orgs/$orgName/repos"
	else
		echo "$(date +"%Y-%m-%d %T") | Organization Name Not Found in Configuration File!"
		exit 1
	fi
else
	echo "$(date +"%Y-%m-%d %T") | Configuring User Repository URL"
	if [[ "$userRepoName" != "" ]]; then
		echo "$(date +"%Y-%m-%d %T") | User Repository"
		gitApiUrl="https://api.github.com/users/$userRepoName/repos"
	else
		echo "$(date +"%Y-%m-%d %T") | User Repository Name Not Found in Configuration File!"
		exit 1
	fi
fi

# If GitHub API URL is not constructed then exit
if [[ $gitApiUrl -eq '' ]]; then
	echo "$(date +"%Y-%m-%d %T") | ERROR : GitHub Api Url Empty. Exiting Program!"
	exit 1
fi


#echo "Username : $username , Usertoken : $usertoken"

# Create Backup Directory
mkdir -p $backupDir

# If Backup Directory Does Not Exists then exit
if [ -d $backupDir ] ; then
        echo "$(date +"%Y-%m-%d %T") | Backup directory exists"
else
        echo "$(date +"%Y-%m-%d %T") | ERROR : Backup directory does not exists"
	exit 1
fi

# IF User Token / Password Exists then pull all repository with Authentication. Else pull public repository
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
# Read Each Repository and Pull Repository
while IFS= read -r repoUrl; do
	cd $backupDir
	repoDir=$(echo $repoUrl | awk -F '/' '{ print $NF }' )
	if [[ ! -z ${usertoken} ]]; then
		repoUrl=$(echo "${repoUrl/https\:\/\//https://$username:$usertoken@}")
	fi
	cloneDir="${backupDir}/${repoDir}"
	echo "$(date +"%Y-%m-%d %T") | Repository Url: $repoUrl"
	echo "$(date +"%Y-%m-%d %T") | Clone Dir: $cloneDir"

	# If Clone Directory Exists then fetch updates only. Else Clone the repository. 
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

	# If No Remote Branch Found then do nothing. Else pull the repository.
	$branchList=$(cd $cloneDir && git branch -r)
        if [ -z $(cd $cloneDir && git branch -r) ]; then
		echo "$(date +"%Y-%m-%d %T") | No Remote Branch Found"
	else
		echo "$(date +"%Y-%m-%d %T") | Branch Found. Pulling all Branches"
		cd $cloneDir/ && git pull --all
        fi


done <<< "$repoList"


echo "$(date +"%Y-%m-%d %T") | Total Updated: $updatedCount"
echo "$(date +"%Y-%m-%d %T") | Total New: $createdCount"
echo "$(date +"%Y-%m-%d %T") | Completed"
