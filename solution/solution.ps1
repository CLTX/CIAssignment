# Setting preferences and paths variables
    $ErrorActionPreference = "Stop"
    $global:scriptPath = $MyInvocation.MyCommand.Path;
    $global:scriptName = [io.path]::GetFileNameWithoutExtension($scriptPath);
    $global:executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent;
    $gitpath = $executingScriptDirectory + "\git"

# Importing modules. 
    Invoke-Expression "$executingScriptDirectory\tools\DotNetCore.1.1.0-WindowsHosting.exe /install /quiet /norestart"
    Import-Module $executingScriptDirectory\lib\utils.ps1 -Force
    Import-Module $executingScriptDirectory\lib\SqlQuery.ps1 -Force

############## 
### PHASE 1 ##
##############
# Install packages (I had to use these because were not available/Shutdown in Choco)
    Invoke-Expression "$executingScriptDirectory\tools\dotnet-dev-win-x64.1.0.0-preview2-1-003177.exe /install /quiet /norestart"  # dotnet SDK Not available in Choco
    Invoke-Expression "$executingScriptDirectory\tools\NDP461-DevPack-KB3105179-ENU.exe /install /quiet /norestart"  # NDP461 Not available in Choco
    
# Install Chocolatey + poshgit 
    chocoinstall
    chocoinstallmodules -moduleToInstall poshgit
    chocoinstallmodules -moduleToInstall dotnetcore
    chocoinstallmodules -moduleToInstall dotnetcore-sdk

#Configuring GIT
    gitglobalsettings -userName "Test" -userEmail "demo@test.nl"

#create Git folder
    createfolder -folderpath $gitpath

##############
### PHASE 2 ##
##############
#Git repo cloning
    repocloning -gitpath $gitpath -repoURL "https://github.com/Teletrax/CIAssignment.git"

# Restore .net core package
    cd $gitpath
    dotnet restore
     
# Build requested apps
    dotnetbuild -buildpath "$gitpath\src\FourC.Worker.Api"
    dotnetbuild -buildpath "$gitpath\src\FourC.Worker.Backend"

# Compress artifacts
    Compress-Archive -Path "$gitpath\src\FourC.Worker.Api\" -DestinationPath "$gitpath\api.zip"
    Compress-Archive -Path "$gitpath\src\FourC.Worker.Backend\" -DestinationPath "$gitpath\backend.zip"

###############
### PHASE 3 ###
###############
# Install MSDTC, MSMQ, IIS + ASP.NET Core,  
    Install-Dtc
    Install-WindowsFeature MSMQ
    Install-WindowsFeature -name Web-Server -IncludeAllSubFeature
    chocoinstallmodules -moduleToInstall mssqlserver2014express
    chocoinstallmodules -moduleToInstall mssqlservermanagementstudio2014express  # Errors during install.

###############
### PHASE 4 ### 
###############
# Extract zip files
    createfolder -folderpath "$executingScriptDirectory\app"
    unzip -backUpPath $gitpath\api.zip -destination "$executingScriptDirectory\app"
    unzip -backUpPath $gitpath\backend.zip -destination "$executingScriptDirectory\app"

# Connect to Database
    $connectionString = GetConnString -server $env:COMPUTERNAME\SQLEXPRESS -database master -timeout 30
    $conn = OpenConnection -connectionString $connectionString

# Execute the SQL script
    $sqlscript = Get-Content $executingScriptDirectory\git\scripts\dbo.Work.sql
    Get-SqlCmd -connection $conn -query $sqlscript -queryTimeout 90

# Close Connection
    CloseConnection -connection $conn

# Importing IISAdministration module
    import-module IISAdministration

# Deleting any existing website
    get-website | Remove-website


###################################
###################################
### UNTIL HERE EVERYTHING WORKS ###
###################################
###################################

# Creating the website, but as physical path neither settings were detailed, site is created as is 
 New-IISSite -Name assignment -PhysicalPath $executingScriptDirectory\app\FourC.Worker.Api -BindingInformation ":80:*"

# Configure and start backend app in background: Insrtuctions to do it (related to app and not to run it in background), weren't provided.