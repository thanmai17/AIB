#Adds the prerequisite compontes for vdi install

$OSinfo = [System.Environment]::OSVersion.Version
$Version = $OSinfo.Major

if ($Version -eq 6) {

Write-Verbose -Message "Operating System is Windows 2012" -Verbose

Add-WindowsFeature -Name Desktop-Experience,Remote-Assistance,Remote-Desktop-Services,RDS-RD-Server

}
ElseIf ($Version -eq 10) {

Write-Verbose -Message " Operating System is Windows 2016 or 2019" -Verbose

Install-WindowsFeature -Name Remote-Assistance,Remote-Desktop-Services,RDS-RD-Server


}
Else {

Write-Verbose -Message " Invalid Operating System. Installation failed." -Verbose

}
#Restart-Computer -ComputerName $env:COMPUTERNAME
