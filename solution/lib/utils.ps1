
### Install and update GIT using Chocolatey.
#Install chocolatey
function chocoinstall () {
    iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
}

# Install any module using chocolatey     
function chocoinstallmodules () {
    Param ($moduleToInstall)
      choco install $moduleToInstall -y 
      
      if ($moduleToInstall = "poshgit")
      {
        $env:Path += ";C:\Program Files\Git\cmd\"
      }  
}

# Set global settings for git 
function gitglobalsettings {
    Param ($userName, $userEmail)
    Write-Host "Configuring Git globals"
    git config --global user.email $userEmail
    git config --global user.name $userName
}

#Self descriptive name. Does a git clone 
function repocloning {
    Param ($gitpath, $repoURL )
    New-Item -ItemType Directory -Force -Path $gitpath
    git clone $repoURL $gitpath
}

# Create a folder
function createfolder {
    Param ($folderpath)
    If(!(test-path $folderpath))
    {
        New-Item -ItemType Directory -Force -Path $folderpath
    }
}

# Perform the dotnet build after a Path is provided
function dotnetbuild {
    Param ($buildpath)
    cd $buildpath
    dotnet build
}

# Unzip files into a defined folder
function unzip {
    Param ($backUpPath, $destination)
    Add-Type -assembly “system.io.compression.filesystem”
    [io.compression.zipfile]::ExtractToDirectory($backUpPath, $destination)
}

