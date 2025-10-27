function Get-SCOMLinuxAgentVersions {
    <#
.Synopsis
		Get SCOm Agent Versions
.Description
		Get the SCOM agent versions and write to LinuxAgentVer.csv
.Example
	Get-SCOMAgentVersion 
	Retrieves all the SCOM windows agent versions and stores the output in LinuxAgentVer.csv
	The data is also
#>
    # Get Windows Agents
    $Agents = Get-SCXAgent
	
    # Export to csv
    #$Agents | select  -Property @{n='PatchListStr';e={$_.Patchlist.Value}}, Version, Name, IPAddress|sort PatchListStr,Name | Export-Csv -Path agtver.csv -NoTypeInformation
    $Agents | Select-Object -Property @{n = 'InMM'; e = { (Get-SCOMClassInstance -I $_.Id).InMaintenanceMode } }, AgentVersion, Name, IPAddress | Sort-Object PatchListStr, Name | Export-Csv -Path LinuxAgentVer.csv -NoTypeInformation
	
    # All SCOMAgent info plus PatchListstr
    $Agents | Select-Object -Property @{n = 'InMM'; e = { (Get-SCOMClassInstance -I $_.Id).InMaintenanceMode } }, *
	
    Write-Host "exported data to LinuxAgentVer.csv"
	
	
}