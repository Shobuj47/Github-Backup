# Repository Backup

These scripts shall clone / checkout all repository under a specific User/Organization from GitHub.
Users shall be able to create archive Backup from SVN Repositories.

There is 3 Different Shell Script:
* [git-backup.sh](./git-backup.sh) [To fetch all the repositires in Linux Bash Shell, ](#linux-bash-shell-script)
    * [git-credential.json](./git-credential.json) [Configuration File ](#configure-json-configuration-file)
* [git-backup.ps1](./git-backup.ps1) [To fetch all the repositories in Windows Powershell, ](#windows-powershell-script)
    * [git-credential.json](./git-credential.json) [Configuration File ](#configure-json-configuration-file)
* [svn-backup.sh](./svn-backup.sh) [To create archive backup of SVN Repositories. ](#svn-backup-archiving)

## Getting Started with GitHub Repositories Checkout

### Configure Json Configuration File

User shall be able to Fetch All Repository from a single Github User/Organization.  
If Authentication parameters are suplied in [git-credential.json](./git-credential.json) configuration file, then the script shall fetch all accesible repositories from that User/Organization.  
If the 'password' parameter is set empty in the [git-credential.json](./git-credential.json) file then the script shall fetch all publicly accesible repositories from that User/Organization.  
User must need to provide 'orgname' or 'userreponame' in the [git-credential.json](./git-credential.json) configuration file.  
* **'orgname'** stores the **'Organization Account Name'** from Github
* **'userreponame'** stores the **'User Account Name'** from GitHub

In the **'password'** parameter within the configuration file add **'Personal access tokens'** from GitHub.  To learn about the 'Personal access tokens' from GitHub you may follow this [link](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-token).

### Linux Bash Shell Script

To execute the bash shell program the package 'jq' needs to be installed into the system. 
To Install 'jq' into the system follow the [link](https://stedolan.github.io/jq/download/).
After installation of the 'jq' add necessary configuration in the [git-credential.json](./git-credential.json) file. 

If the target repositories owner is an Organization then execute:
```sh git-backup.sh 1```
or
```./git-backup.sh 1```

If the target repositoriew owner is an User then execute:
```sh git-backup.sh```
or
```./git-backup.sh```

### Windows PowerShell Script

### SVN Backup Archiving
