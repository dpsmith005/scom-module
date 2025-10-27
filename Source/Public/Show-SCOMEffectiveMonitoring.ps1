Function Show-SCOMEffectiveMonitoring {
	<#
	.Synopsis
    Retrieve Rules, Monitors, and Classes.  Export the efective monitoring for the windows server
	.Description
    Retrieve Rules, Monitors, and Classes and display in gridview.  Export the effective monitoring to a CSV file for the specified server
	.Parameter server
    Name of SCOM Windows server to retrieve information from
	.Example
    function-name
    provides example how the script or function works with any parameters
	.Inputs
    What inputs can be passed via pipe
	.OutPuts
    Output from the script or function
	.Notes
    NAME:     Show-SCOMEffectiveMonitoring
    AUTHOR:   David Smith
    LASTEDIT: 28 April 2025
#>
	param([Parameter(Mandatory = $true)][String]$server )

	# Retrieve all instances for the server specified
	$instance = Get-SCOMClassInstance *$server*

	# Display the Rules in a gridview
	Write-host "Displaying Rules in GridView"
		($instance.GetmonitoringRules() | Select-Object * | Out-GridView -Title "Rules");
	#((Get-SCOMClassInstance *$server*).GetmonitoringRules()|select XmlTag,DisplayName,name,ManagementPackName|Sort DisplayName |Out-GridView);

	# Display the Monitor objects in a gridview
	Write-host "Displaying MonitoringObjects in GridView"
		($instance.GetRelatedMonitoringObjects() | Select-Object * | Out-GridView -Title "Monitoring Objects");

	# Display the Monitor Details in a gridview
	Write-host "Displaying MonitoringObjects Values in GridView"
		($instance.GetRelatedMonitoringObjects() | Select-Object -ExpandProperty values | out-gridView -Title "Monitoring details");

	# Display classes wher this object is member
	Write-Host "Displaying the Classes with which this server is a member"
	$instance.GetMonitoringClasses() | Select-Object -Property * -ExcludeProperty PropertyCollection, OptimizationCollection, Identifier, Base, ManagementGroupId | Out-GridView -Title "Classes"

	#$instance.getMonitoringRelationshipObjects() | select *, @{N = "RelationshipDisplayName"; E = { foreach ($r in $relationships) { if ($r.id -match $_.MonitoringRelationshipClassId) { $r.DisplayName } } } } | Out-GridView
	#$Instance.GetMonitoringDiscoveries

	# export the SCOM effective monitoring to a csv
	$outFile = ".\" + $server + "_EffectiveMonitoring.csv"
	$MonitoringObject = (Get-SCOMGroup -DisplayName "All Windows Computers").GetRelatedMonitoringObjects() | Where-Object { $_.DisplayName -match $server }
	Export-SCOMEffectiveMonitoringConfiguration -Instance $MonitoringObject -Path $outFile
	# Convert the | separator into a comma and change header column names
	$header = Get-Content $outFile | Select-Object -first 1
	$newHeaders = @()
	$i = 1
	foreach ($h in  $header.split('|')) {
		if ($h -eq 'Parameter Name') {
			$h = $h + " $i"
		}
		if ($h -eq 'Default Value') {
			$h = $h + " $i"
		}
		if ($h -eq 'Effective Value') {
			$h = $h + " " + $i.ToString()
			$i++
		}
		$newHeaders += $h
	}
	$Headers = $newHeaders -join ","

	$oldData = Get-Content $outFile | Select-Object -skip 1
	$Data = $oldData.Replace("`0", '').Replace('|', ",")

	$Headers | out-file $outFile
	$Data | out-file $outFile -append
	#$results = import-csv $outFile
}