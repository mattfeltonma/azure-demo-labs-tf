# Setup logging
Start-Transcript -path "C:\MachinePrep\logs\log.txt"

# Create directory to store installation files
New-Item -ItemType directory -Path C:\MachinePrep\files

try {
    # Install RSAT Tools
    Write-Host "Installing RSAT Tools..."
    Install-WindowsFeature -IncludeAllSubFeature RSAT
}
catch {
    Write-Host "Unable to install RSAT Tools"
}

try {

    # Install nuget package manager
    Write-Host "Installing nuget..."
    Install-PackageProvider -Name Nuget -Force 

    # Install Azure CLI
    Write-Host "Downloading Azure CLI..."
    $uri = "https://aka.ms/installazurecliwindows"
    Invoke-WebRequest -Uri $uri -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

    # Install Azure PowerShell
    Write-Host "Installing Azure CLI..."
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
}

catch {
    Write-Host "Unable to install Azure CLI"
}

try {

    # Download Visual Studio Code
    Write-Host "Installing Visual Studio Code"
    $uri = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
    $destination = "C:\MachinePrep\files\visualstudiocode.exe"
    Invoke-WebRequest -Uri $uri -OutFile $destination

    # Install Visual Studio Code
    Start-Process $destination -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode' -Wait
    
}

catch {
    Write-Host "Unable to install Visual Studio Code"
}

try {

    # Download Google Chrome browser
    Write-Host "Downloading and installing Google Chrome..."
    $uri = "https://dl.google.com/chrome/install/chrome_installer.exe"
    $destination = "C:\MachinePrep\files\chrome_installer.exe"
    Invoke-WebRequest -Uri $uri -OutFile $destination

    # Install Google Chroome
    Start-Process -FilePath $destination -ArgumentList '/silent /install' -Wait
}

catch {
    Write-Host "Unable to install Google Chrome"
} 

Stop-Transcript