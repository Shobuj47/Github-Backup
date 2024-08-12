#!/bin/bash
set -e
echo "
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
"

scriptsBase="$( cd "$( dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd )"
backupDir="$scriptsBase/git_backup"
orgName=''
userRepoName=''
pageCount=1
gitApiUrl=""
updatedCount=0
createdCount=0

isOrganization=$1

reposCount=$2
echo "Fetch Total Repository : $reposCount"

if [[ $reposCount -gt 100 ]]; then
        pageCount=`echo "($reposCount / 100) + 0.5" | bc`
        pageCount=`echo "$pageCount" | awk '{printf("%d\n",$1)}'`
else
        reposCount=100
fi
echo "Total $pageCount pages"

echo "--------------"

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
        currentPage=1
        while [[ $pageCount -ge $currentPage ]]
        do
                echo "========================================================================"
                echo "$(date +"%Y-%m-%d %T") | Page $currentPage Fetching Started"
                echo "========================================================================"
                echo "$(date +"%Y-%m-%d %T") | Getting data from ${gitApiUrl}?per_page=100&page=$currentPage"
                repoList=$( curl --header "Authorization: token $usertoken" "${gitApiUrl}?per_page=100&page=$currentPage" | jq -r ".[].clone_url" )
                currentPage=`echo "$currentPage + 1" | bc`


                # Read Each Repository and Pull Repository
                while IFS= read -r repoUrl; do
                        cd $backupDir
                        repoDir=$(echo $repoUrl | awk -F '/' '{ print $NF }' )
                        if [[ ! -z ${usertoken} ]]; then
                                repoUrl=$(echo "${repoUrl/https\:\/\//https://$username:$usertoken@}")
                                echo "$(date +"%Y-%m-%d %T") | Repository URL: $repoUrl"
                        fi
                        cloneDir="${backupDir}/${repoDir}"
                        echo "$(date +"%Y-%m-%d %T") | Repository Url: $repoUrl"
                        echo "$(date +"%Y-%m-%d %T") | Clone Dir: $cloneDir"

                        # If Clone Directory Exists then fetch updates only. Else Clone the repository.
                        if [[ -d $cloneDir ]]; then
                                echo "$(date +"%Y-%m-%d %T") | Existing Local Repository! Getting Updates >>>"
                                cd $cloneDir/ && git fetch --all
                                updatedCount=`echo "$updatedCount+1" | bc`
                        else
                                echo "$(date +"%Y-%m-%d %T") | New Local Repository! Cloning from remote >>>"
                                git clone $repoUrl $cloneDir
                                echo "$(date +"%Y-%m-%d %T") | Pulling All Branches"
                                createdCount=`echo "$createdCount+1" | bc`
                        fi

                        # If No Remote Branch Found then do nothing. Else pull the repository.
                        echo "$(date +"%Y-%m-%d %T") | Checking branch list"
                        branchList=`cd $cloneDir && git branch -r`
                        if [[ -z $branchList ]]; then
                                echo "$(date +"%Y-%m-%d %T") | No Remote Branch Found"
                        else
                                echo "$(date +"%Y-%m-%d %T") | Branch Found. Pulling all Branches"
                                cd $cloneDir/ && git pull --all
                        fi
                done <<< "$repoList"


                echo "========================================================================"
                echo "$(date +"%Y-%m-%d %T") | Page $currentPage Fetching Completed"
                echo "========================================================================"
                sleep 10s
        done
fi

echo "$(date +"%Y-%m-%d %T") | Total Updated: $updatedCount | Total Created: $createdCount"
echo "$(date +"%Y-%m-%d %T") | Completed"
