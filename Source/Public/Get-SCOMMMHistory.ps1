function Get-SCOMMMHistory {
    <#
  .Synopsis
    Get SCOM maintenance mode history
   .Description
    Get SCOM maintenance mode history for all systems or specified systems
   .Parameter Computer
    Name of the SCOM computer to retrieve MM history or multiple comma seperated list of computers
    The paramter is used to supply input to the script to gather MM history
    .Example
    $array = Get-MMHistory
    This wil return the MM history for all windows computers and store the results in $array
    .Example
    Get-MMHistory tsmgr4
    This will get the history for the specified Windows server
    .Example
    Get-MMHistory tsmgr3,tsmgr4
    This will ge the history for the specified Windows servers
   .Inputs
   SCOM Windows computer name or multiple computer names
   .OutPuts
    Maintenance mode history for all nodes or the specified node
   .Notes
    NAME:  Get-MMHistory
    AUTHOR: David Smith
    LASTEDIT: date 25 April 2025
    KEYWORDS:
   .Link
     Http://www.domain.org
 #Requires -Version 5.0
 #>
    param([string[]]$Computer)

    class MM {
        [string]$ServerName
        [Nullable[datetime]]$StartTime
        [Nullable[datetime]]$ScheduledEndTime
        [Nullable[datetime]]$EndTime
        [Nullable[datetime]]$LastModified
        [string]$Comments
        [string]$Reason
        [string]$User
        [string]$MonitoringObjectId
    }
    #[string]$ManagementGroup   [string]$ManagementGroupId  

    $WinClass = Get-SCOMClass -name Microsoft.Windows.Computer
    if ($Computer) {
        #$Instances = $WinClass | Get-SCOMClassInstance | Where-Object { $_.DisplayName -match "$computer" }
        $Instances = $WinClass |  Get-SCOMClassInstance | Where-Object { $serversArray -contains ($_.DisplayName.Split("."))[0] }
    }
    else {
        $Instances = $WinClass | Get-SCOMClassInstance 
    }        
    $tot = $Instances.count
    $i = 1
    $arrResults = @()
    foreach ($inst in $Instances) {
        $pct = [int](($i / $tot) * 100)
        Write-Progress -Activity "Processing" -Status "Progress-> $i or $tot    $pct %" -PercentComplete $pct -CurrentOperation $inst.DisplayName
        $i++
        try {
            $result = $inst | Get-SCOMMaintenanceMode -History | Select-Object  *, @{N = "ServerName"; E = { $inst.DisplayName } }
            if ($result.count -gt 1) { $result; $return }
            if ([string]::IsNullOrEmpty($result)) {
                # No MM History
                $MMResult = [MM]::new()
                $MMResult.Comments = "Get MM history returned NULL"
                $MMResult.ServerName = $inst.DisplayName
                $MMResult.Reason = "No History"
                $arrResults += $MMResult
            }
            else {
                Foreach ($r in $result) {
                    $MMResult = [MM]::new()
                    $MMResult.Comments = $r.Comments
                    $MMResult.StartTime = $r.StartTime
                    $MMResult.EndTime = $r.EndTime
                    $MMResult.LastModified = $r.LastModified
                    #$MMResult.ManagementGroup = $r.ManagementGroup
                    #$MMResult.ManagementGroupId = $r.ManagementGroupId
                    $MMResult.MonitoringObjectId = $r.MonitoringObjectId
                    $MMResult.Reason = $r.Reason
                    $MMResult.ScheduledEndTime = $r.ScheduledEndTime
                    $MMResult.ServerName = $inst.DisplayName
                    $MMResult.User = $r.User
                    $arrResults += $MMResult 
                }
            }
            Remove-Variable result, MMresult
        }
        catch {
            Write-Host RESULT: $result
            Write-Host $MMResult
            Write-Host ERROR $i - $inst.DisplayName
            Write-error -message "ERROR" -ErrorAction Stop
        }
    }
    return $arrResults
}