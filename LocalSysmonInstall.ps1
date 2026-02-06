<#
.SYNOPSIS
Installs Sysmon from external source.

.DESCRIPTION
PowerShell script or module to install Sysmon with configuration

.NOTES

    Filename: Sysmon-Install-Local.ps1
    Author: Oskars E. Zviedris
    Modified date: 2023-05-22
    Version 1.0

    !!!IMPORTANT!!!

        Replace "$ExternalSysmonPath = 'C:\YOUR_PATH_HERE'" with the folder where your external Sysmon64.exe is located.
            
                            e.g. $ExternalSysmonPath = 'G:\Files\Sysmon_unzipped'

        Add path to '.XML' configuration file for Sysmon, if needed.
        
                            e.g. $SysmonXmlFilePath = 'G:\Files\Sysmon_unzipped\your_config_name.xml'



#Extras for item list:
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Sysmon/Operational",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Publishers\{5770385f-c22a-43e0-bf4c-06f5698ffbd9}",
    "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\EventLog-Microsoft-Windows-Sysmon-Operational"
#>
#You can change these parameters
$ExternalSysmonPath = 'C:\Your\Path\Here'
$SysmonXmlFilePath = ''

#Version output number formating
$VersionFormat = "{0}.{1}.{2}.{3}"

#Changing these can break the script
$TempFolder = "$env:TEMP\Sysmon"
$LogFile = "$env:TEMP\SysmonUpdate.log"
$items = @(
    "HKLM:\SYSTEM\CurrentControlSet\Services\Sysmon64",
    "HKLM:\SYSTEM\CurrentControlSet\Services\SysmonDrv",
    "HKLM:\SYSTEM\ControlSet001\Services\Sysmon64",
    "HKLM:\SYSTEM\ControlSet001\Services\SysmonDrv",
    "HKLM:\SYSTEM\ControlSet002\Services\Sysmon64",
    "HKLM:\SYSTEM\ControlSet002\Services\SysmonDrv"
)


# Define functions

Function Get-SysmonLocation{
    if (Test-Path "C:\Windows\Sysmon64.exe"){
        return Get-ChildItem "C:\Windows\Sysmon64.exe"
    } else {
        return $null }
}

Function Get-SysmonExternalLocation{
    return Get-ChildItem $ExternalSysmonPath -Filter Sysmon64.exe -ErrorAction SilentlyContinue | Select -First 1
}

Function Get-SysmonCurrentVersion{
    $currentExe = Get-SysmonLocation
    if($currentExe){
        return $currentExe.VersionInfo | % {($VersionFormat -f $_.ProductMajorPart,$_.ProductMinorPart,$_.ProductBuildPart,$_.ProductPrivatePart)}
    } else {
        return $null
    }
    return Get-ChildItem 
}

Function Get-SysmonExternalVersion{
    $extExe = Get-SysmonExternalLocation
    if($extExe){
        return $extExe.VersionInfo | % {($VersionFormat -f $_.ProductMajorPart,$_.ProductMinorPart,$_.ProductBuildPart,$_.ProductPrivatePart)}
    } else {
        return $null
    }
    return Get-ChildItem
}

Function Compare-Versions{
    if ($InstalledVersion -ge $ExternalVersion){
        Write-Host "Current version of Sysmon64 is the same as the one located at: '$ExternalSysmonPath'." -ForegroundColor DarkGreen
        ""
        ""
        ""
        ""
        Write-Host "Exiting..." -ForegroundColor DarkYellow
        ""
        exit

    } else {
        if ($null -eq (Get-SysmonLocation)){
            Write-Host "Sysmon64 isn't installed on this system." -ForegroundColor Red
            ""
            ""
            Write-Host "Sysmon64 will be installed from: '$ExternalSysmonPath' directory..." -ForegroundColor DarkYellow
        } else {
            Write-Host "Newer version of Sysmon64 will be installed from: '$ExternalSysmonPath' directory..." -ForegroundColor DarkYellow
        }
    }
}

Function New-TempEnvironment{
    if(-not (Test-Path $TempFolder)){
        mkdir $TempFolder
        ""
        ""
        Write-Host "Created $TempFolder" -ForegroundColor Green
        ""
    }
}

function Remove-TempEnvironment{
    Get-ChildItem $TempFolder -Recurse | Remove-Item -Force
    Remove-Item $TempFolder
    ""
    Write-Host "Removed $TempFolder and it's contents." -ForegroundColor Green
    ""
}

function DownloadExtSysmon{
    Copy-Item -Path $ExternalSysmonPath/Sysmon64.exe  -Destination $TempFolder -Force -Verbose
    ""
    ""
    Write-Host "Downloaded external version of Sysmon and copied to $TempFolder" -ForegroundColor Green
    ""
}

function Stop_Sysmon_Services{
    if ($null -eq $svcSysmon64Status){
        $svcSysmon64Status = Get-Service -Name Sysmon64 -ErrorAction SilentlyContinue
        Write-Host "Service Sysmon64 doesn't exist." -ForegroundColor DarkYellow
    } else {
        Write-Host "Stopping Sysmon64 service..." -ForegroundColor DarkYellow
        Stop-Service -Name "Sysmon64" -ErrorAction SilentlyContinue
    }
    if ($null -eq $svcSysmonDrvStatus){
        $svcSysmonDrvStatus = Get-Service -Name SysmonDrv -ErrorAction SilentlyContinue
        Write-Host "Service SysmonDrv doesn't exist." -ForegroundColor DarkYellow
    } else {
        Write-Host "Stopping SysmonDrv service..." -ForegroundColor DarkYellow
        Stop-Service -Name "SysmonDrv" -ErrorAction SilentlyContinue
    }
}

function Uninstall-Sysmon{
    $Installed = Get-SysmonLocation
    if($Installed){
        & sysmon64 -u force
        $Installed | Remove-Item
        ""
        ""
        Write-Host "Uninstalled $($Installed.FullName)" -ForegroundColor Green
        ""
    } else {
        ""
        ""
        return Write-Host "Sysmon64 was not found." -ForegroundColor DarkYellow
        ""
        ""
        ""
        ""
    }
    foreach ( $i in $items ) {
    $error.Clear();
    Remove-Item -Path $i -Force -Recurse -ErrorAction SilentlyContinue
    If($error) {
        $result = $error.Exception.Message
    } Else {
        $result = "O : $i"
    }
    }
    
}

function Install-Sysmon{
    & $TempFolder\Sysmon64.exe -accepteula -i $SysmonXmlFilePath
}

function Check-Sysmon-Update-Results{
    if ($null -eq (Get-SysmonLocation)){
        ""
        ""
        Write-Host "Sysmon64.exe was not found in C:\Windows directory." -ForegroundColor Red
        ""
        ""
    } else {
        if ($InstalledVersion -ge $ExternalVersion){
            Write-Host "Sysmon64 has been updated successfully!" -ForegroundColor DarkGreen
        } else {
            Write-Host "Sysmon64 update has failed!" -ForegroundColor Red
        }

    }
}



#Calling functions...
$InstalledVersion = Get-SysmonCurrentVersion
$ExternalVersion = Get-SysmonExternalVersion

clear
""
""
""
Get-Date | Tee-Object -FilePath $LogFile -Append
""
""
""
Write-Host "Checking for versions of Sysmon64..." -ForegroundColor DarkYellow
""
""
"Installed version of Sysmon64: $InstalledVersion" | Tee-Object -FilePath $LogFile -Append
"External version of Sysmon64: $ExternalVersion" | Tee-Object -FilePath $LogFile -Append
""
""
""
#Comparing Sysmon versions...
Compare-Versions
""
""

#Downloading Sysmon to local system...
New-TempEnvironment
DownloadExtSysmon

#Uninstalling Sysmon...
Stop_Sysmon_Services
Start-Sleep -Seconds 1.0
Uninstall-Sysmon

#Installing Sysmon...
Install-Sysmon

#Removing residue files...
Remove-TempEnvironment


#Checking for Sysmon versions after install...
""
""
""
"Installed version of Sysmon64: $InstalledVersion" | Tee-Object -FilePath $LogFile -Append
"External version of Sysmon64: $ExternalVersion" | Tee-Object -FilePath $LogFile -Append
""
""
""
#Checking for success...
Check-Sysmon-Update-Results

#Exiting...
""
""
""
""
Write-Host "Exiting..." -ForegroundColor DarkYellow
""
exit
