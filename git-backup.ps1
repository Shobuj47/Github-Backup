
$baseDir=Get-Location
$gitCredentialConfigFile="$baseDir\git-credential.json"
$repositoryListConfigFile="$baseDir\repository_list.txt"
$repositoryDir="$baseDir\Repositories"

echo "######################################################"
echo "Started $(Get-Date)"
echo "######################################################"

$gitCredentialConfig = Get-Content -Path $gitCredentialConfigFile | ConvertFrom-Json
[string[]]$repositoryList = Get-Content -Path $repositoryListConfigFile
[string[]]$existingRepolist = Get-ChildItem -Directory -Path $repositoryDir
foreach ($repositoryName in $repositoryList) {
    $isExisting = 0

    # If Existing Repository Then Get Update
    if ($existingRepolist.Count -gt 0){
        foreach($existingRepo in $existingRepolist){
            If ($existingRepo -eq $repositoryName){
                echo "Existing Repository: $existingRepo"
                $isExisting = 1
                cd "$repositoryDir/$repositoryName"
                $gitUrlConstruct="https://$($gitCredentialConfig.username):$($gitCredentialConfig.password)@github.com/$($gitCredentialConfig.username)/$($repositoryName)"
                $branch = git branch --show-current
                #git pull origin $branch
                git pull --all
                break
            }else{
                $isExisting = 0
            }
        }
    }

    # If Repository Does Not Exists
    If($isExisting -eq 0){
        echo "New Repository: $existingRepo"
        New-Item -Path $repositoryDir -Name $repositoryName -ItemType "directory"
        cd "$repositoryDir/$repositoryName"
        git init
        git config user.email "$($gitCredentialConfig.email)"
        git config user.name "$($gitCredentialConfig.username)"
        $gitUrlConstruct="https://$($gitCredentialConfig.username):$($gitCredentialConfig.password)@github.com/$($gitCredentialConfig.username)/$($repositoryName)"
        git clone $gitUrlConstruct
        git remote add origin "https://github.com/$($gitCredentialConfig.username)/$($repositoryName)"
        git pull --all
        $branch = git branch -r
        git pull origin $branch.split("/")[1]
        git pull --all
    }
}

cd $baseDir

echo "######################################################"
echo "Done $(Get-Date)"
echo "######################################################"