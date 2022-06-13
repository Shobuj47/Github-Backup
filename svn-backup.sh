#!/bin/bash

currentDate=$(date "+%d_%m_%Y")

#directory informations
svnhome="/svn/repos"
dumphome="/svn/svn_dump"
dumpdir="$dumphome/$currentDate"

mkdir -p $dumpdir
# If Backup Directory Does Not Exists then exit
if [ -d $dumpdir ] ; then
        echo "$(date +"%Y-%m-%d %T") | Backup directory exists"
else
        echo "$(date +"%Y-%m-%d %T") | ERROR : Backup directory does not exists"
	exit 1
fi

#Dump each repository into a directory
for repos in $(ls $svnhome)
do
	echo "$(date +"%Y-%m-%d %T") | Dumping now $repos"
	svnadmin dump $svnhome/$repos | gzip               >       ${dumpdir}/${repos}.svn.gz
done


echo "$(date +"%Y-%m-%d %T") | Task Completed"
