#Gets script root path
$Url = "https://aibgrid.blob.core.windows.net/aib/VDAServerSetup_1912.exe"
$Installer = "$env:SystemRoot\Temp\$(Split-Path -Path $Url -Leaf)"
# Download VDA Agent installer;
Write-Verbose -Message "Downloading $Url to $Installer"
Invoke-WebRequest -URI $Url -OutFile $Installer
$ScriptsFolder = $Installer

Function InstallVDI {
    Param(
        [Parameter(Mandatory = $True)]
        [String]
        $domainNames,
        [Parameter(Mandatory = $True)]
        [String] 
        $scriptRootPath
    )

    #list of ddc comma seprated
    $ddc = @( -join $domainNames)

    $vda = @("VDA")

    $softwarePath = "$scriptRootPath"
    
    try {
        if (Test-Path $softwarePath -PathType Leaf) {
        
            $excludeArg = '"Smart Tools Agent","personal vDisk","Citrix Telemetry Service"'
            $installArgs = "/QUIET /COMPONENTS $vda /CONTROLLERS $ddc /ENABLE_HDX_PORTS /OPTIMIZE /ENABLE_REMOTE_ASSISTANCE /EXCLUDE $excludeArg /VIRTUALMACHINE /DISABLEEXPERIENCEMETRICS /NOREBOOT"
            Start-Process -FilePath $softwarePath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
        }
        else {
            Write-Verbose -Message "Could not find VDA Setup files"  
        }
    } 
    catch {
        $_.Exception | Format-List -Force
    }

}

#reads the ddc's from the text file
#$data = [IO.File]::ReadAllText("$ScriptsFolder\data.txt")

#Gets the postion of colon 
#$pos = $data.IndexOf("=")

#Gets the ddc's after the equal 
$hostNames = "ubs-win-test01.ubsad.com,ubs-win-test02.ubsad.com"

#Runs the setup process
InstallVDI -domainNames $hostNames -scriptRootPath $ScriptsFolder

#Restarts the system after installation
Restart-Computer -ComputerName $env:COMPUTERNAME

