# Requires -Version 3
<#
    .SYNOPSIS
        Downloads and installs the FSLogix Apps agent.

    .DESCRIPTION
        Downloads and installs the FSLogix Apps agent. Checks whether the agent is already installed. Installs the agent if it is not installed or not up to date.
        Configures a scheduled task to download the FSLogix App Masking and Java Version Control rulesets from an Azure blog storage container.
#>
Param (
    [Parameter()]$LogFile = "$env:ProgramData\fslogix\Logs\$($MyInvocation.MyCommand.Name).log",
    [Parameter()]$Target = "$env:ProgramData\fslogix\Scripts",
    #[Parameter()]$ScriptUrl = "https://AIBOrg@dev.azure.com/AIBOrg/AIB/_git/AIB/Imagebuild/FSLogix.ps1",
    #[Parameter()]$Script = (Split-Path -Path $ScriptUrl -Leaf),
    #[Parameter()]$TaskName = "Get FSLogix Ruleset",
    #[Parameter()]$Group = "NT AUTHORITY\SYSTEM",
    [Parameter()]$Execute = "powershell.exe",
    [Parameter()]$ScriptArguments = "-ExecutionPolicy Bypass -NonInteractive -WindowStyle Minimized -File $Target\$Script",
    [Parameter()]$InstallerArguments = "/install /quiet /norestart",
    [Parameter()]$VerbosePreference = "Continue"
)
Set-ExecutionPolicy Bypass -Force
Start-Transcript -Path $LogFile

# Set installer download URL based on processor architecture
Switch ((Get-WmiObject Win32_OperatingSystem).OSArchitecture) {
    "32-bit" { Write-Verbose -Message "32-bit processor"; $Url = "https://aibgrid.blob.core.windows.net/aib/FSLogixAppsSetup.exe" }
    "64-bit" { Write-Verbose -Message "64-bit processor"; $Url = "https://aibgrid.blob.core.windows.net/aib/FSLogixAppsSetup.exe" }
}
$Installer = "$env:SystemRoot\Temp\$(Split-Path -Path $Url -Leaf)"

# Download FSLogix Agent installer; Get file info from the downloaded file to compare against what's installed
Write-Verbose -Message "Downloading $Url to $Installer"
#Start-BitsTransfer -Source $Url -Destination $Installer -Priority High -TransferPolicy Always -ErrorAction Continue -ErrorVariable $ErrorBits
Invoke-WebRequest -URI $Url -OutFile $Installer
$ProductVersion = (Get-ItemProperty -Path $Installer).VersionInfo.ProductVersion
If ($ProductVersion) { Write-Verbose -Message "Downloaded FSLogix Apps version: $ProductVersion." } Else { Write-Verbose -Message "Unable to query downloaded FSLogix Apps version." }

# Determine whether FSLogix Agent is already installed
Write-Verbose -Message "Querying for installed FSLogix Apps version."
$Agent = Get-WmiObject -Class Win32_Product -ErrorAction Continue | Where-Object { $_.Name -Like "FSLogix Apps" } | Select-Object Name, Version
If ($Agent) { Write-Verbose -Message "Found FSLogix Apps $($Agent.Version)." }

# Install the FSLogix Agent
If (Test-Path $Installer) {
    # If installed version less than downloaded version, install the update
    If (!($Agent) -or ($Agent.Version -lt $ProductVersion)) {
        Write-Verbose -Message "Installing the FSLogix Agent $ProductVersion."; 
        Start-Process -FilePath $Installer -ArgumentList $InstallerArguments -Wait
        Write-Verbose -Message "Deleting $Installer"; Remove-Item -Path $Installer -Force -ErrorAction Continue
        Write-Verbose -Message "Querying for installed FSLogix Agent."
        $Agent = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -Like "FSLogix Apps" } | Select-Object Name, Version
        Write-Verbose -Message "Installed FSLogix Agent: $($Agent.Version)."
    } Else {
        # Skip install if agent already installed and up to date
        Write-Verbose -Message "Skipping installation of the FSLogix Agent. Version $($Agent.Version) already installed."
    }
} Else {
    Write-Verbose -Message "Unable to find the FSLogix Apps installer."
    # If we get here, it's possible the script couldn't download the installer
    # Delete script key under HKLM\SOFTWARE\Microsoft\IntuneManagementExtension to get script to re-run again in ~60 minutes
    $KeyParent = "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies"
    $ScriptName = Split-Path -Path $MyInvocation.MyCommand.Name -Leaf
    $KeyPath = "$KeyParent\$($ScriptName.Split("_")[0])\$($ScriptName.Split("_")[1] -replace ".ps1")"
    If (Test-Path -Path $KeyPath) {
        Write-Verbose -Message "Removing registry key to force script to re-run: $KeyPath"
        Remove-Item -Path $KeyPath -Force
    }
    Stop-Transcript
    Break
}

<#
 If the agent is installed, create the scheduled task
If ($Agent) {
    # Download the script that will download FSLogix ruleset files
    If (!(Test-Path -Path $Target)) { New-Item -Path $Target -ItemType Directory }
    Start-BitsTransfer -Source $ScriptUrl -Destination "$Target\$Script" -Priority High -TransferPolicy Always -ErrorAction Continue -ErrorVariable $ErrorBits

    # Create a scheduled task to run the script
    Write-Verbose -Message "Creating folder redirection scheduled task."
    # Build a new task object
    $action = New-ScheduledTaskAction -Execute $Execute -Argument $ScriptArguments -Verbose
    $trigger =  New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -Hidden -DontStopIfGoingOnBatteries -Compatibility Win8 -Verbose
    $principal = New-ScheduledTaskPrincipal -GroupId $Group -Verbose
    $newTask = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Verbose

    # No task object exists, so register the new task
    Register-ScheduledTask -InputObject $newTask -TaskName $TaskName -Verbose

    # Get the task properties and set the trigger duration and interval
    $Task = Get-ScheduledTask -TaskName $TaskName
    $Task.Triggers.Repetition.Duration = "PT12H"
    $Task.Triggers.Repetition.Interval = "PT2H"
    $Task | Set-ScheduledTask -User $Group
    
}
#>
Stop-Transcript