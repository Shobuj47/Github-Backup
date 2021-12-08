# Github-Backup (Powershell | Bash)

These scripts shall clone / checkout all repository under single user. 


To get started with github backup add Github Credentials in 'git-credential.json' file and then execute the shell script based on the OS to create the backup. 

* If in windows execute "backup.ps1" in powershell.
* If in Linux then execute "git-backup.sh" file.

If the password section is left blank in 'git-credential.json' file then it shall try to clone / checkout public repositories only.

Note: For linux make sure that you have installed 'jq' into the system. Follow the below url to install 'jq' into the system - 
https://stedolan.github.io/jq/download/