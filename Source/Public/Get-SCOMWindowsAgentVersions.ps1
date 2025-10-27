function Get-SCOMWindowsAgentVersions {
	<#
.Synopsis
		Get SCOm Agent Versions
.Description
		Get the SCOM agent versions and write to WindowsAgentVer.csv
.Example
	Get-SCOMAgentVersion 
	Retrieves all the SCOM windows agent versions and stores the output in WindowsAgentVer.csv
	The data is also
#>
	# Get Windows Agents
	$Agents = Get-SCOMAgent
	
	# Export to csv
	#$Agents | select  -Property @{n='PatchListStr';e={$_.Patchlist.Value}}, Version, Name, IPAddress|sort PatchListStr,Name | Export-Csv -Path agtver.csv -NoTypeInformation
	$Agents | Select-Object -Property @{n = 'InMM'; e = { (Get-SCOMClassInstance -I $_.Id).InMaintenanceMode } }, @{n = 'PatchListStr'; e = { $_.Patchlist.Value } }, Version, Name, IPAddress | Sort-Object PatchListStr, Name | Export-Csv -Path WindowsAgentVer.csv -NoTypeInformation
	
	# All SCOMAgent info plus PatchListstr
	$Agents | Select-Object -Property @{n = 'InMM'; e = { (Get-SCOMClassInstance -I $_.Id).InMaintenanceMode } }, @{n = 'PatchListStr'; e = { $_.Patchlist.Value } }, *
	
	Write-Host "exported data to WindowsAgentVer.csv"
	
	
}