#Gets script root path
#$ScriptsFolder = $PSScriptRoot
$Url = "https://aibgrid.blob.core.windows.net/aib/VDAWorkstationSetup_1912.exe"
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
        
            $excludeArg = '"AppDisks VDA Plug-in","Citrix Files for Outlook","Citrix Files for Windows","Personal vDisk"'
            $includeArg = '"User personalization layer","Citrix Telemetry Service","Citrix Universal Print Client","Citrix Supportability Tools","Machine Identity Service","Citrix User Profile Manager","Citrix Personalization for App-V - VDA"'
            #$installArgs = "/QUIET /COMPONENTS $vda /CONTROLLERS $ddc /ENABLE_HDX_PORTS /OPTIMIZE /ENABLE_REMOTE_ASSISTANCE /EXCLUDE $excludeArg /VIRTUALMACHINE /DISABLEEXPERIENCEMETRICS /NOREBOOT"
            $installArgs =  "/controllers $ddc /quiet /enable_remote_assistance /disableexperiencemetrics /virtualmachine /optimize /enable_real_time_transport /enable_hdx_ports /includeadditional $includeArg /exclude $excludeArg /components vda,plugins /mastermcsimage /noreboot"

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
#Restart-Computer -ComputerName $env:COMPUTERNAME

