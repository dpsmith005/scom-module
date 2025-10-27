Function Remove-SCOMAgents {
    <#
.Synopsis
    Remove Agent from SCOM
.Description
    This wilol completely remove a server from SCOM.  This is equiveant to Administration -> Agents -> Select and delete server
.Example
    Remove-SCOMAgents server01,server02,server03 scomms01
    This will remove the servers from scom
.Example
    Remove-SCOMAgents -AgentComputerName $AgentComputerName -MSServer $MSServer
    Removes servers from SCOM by the values set in a variable
.Example
    $MSServer = "management.server.name"
    $groupName = "WSH TS - Windows Servers"
    Remove-SCOMAgents -AgentComputer $((Get-SCOMGroup -DisplayName $groupName).GetRelatedMonitoringObjects().DisplayName) -MSServer $MSServer
    remove the SCOM agents for an entire group
.Notes
    NAME:     Remove-SCOMAgents
    AUTHOR:   David Smith
    LASTEDIT: 9 July 2025
#>
    Param(
        [string[]]$AgentComputerName,
        [string]$MSServer
    )

    [System.Reflection.Assembly]::Load("Microsoft.EnterpriseManagement.Core, Version=7.0.5000.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35") | out-null
    [System.Reflection.Assembly]::Load("Microsoft.EnterpriseManagement.OperationsManager, Version=7.0.5000.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35") | out-null

    function New-Collection ( [type] $type ) {
        $typeAssemblyName = $type.AssemblyQualifiedName;
        $collection = new-object "System.Collections.ObjectModel.Collection``1[[$typeAssemblyName]]";
        return , ($collection);
    }
    
    # Connect to management group
    Write-output "Connecting to management group : $MSServer"

    #$ConnectionSetting = New-Object Microsoft.EnterpriseManagement.ManagementGroup($MSServer)
    #$admin = $ConnectionSetting.GetAdministration()
    New-SCOMManagementGroupConnection -ComputerName $MSServer
    $ConnectionSetting = Get-SCOMManagementGroup
    $admin = $ConnectionSetting.GetAdministration()
    
    Write-output "Getting agent managed computers"
    $agentManagedComputers = $admin.GetAllAgentManagedComputers()

    # Get list of agents to delete
    foreach ($name in $AgentComputerName) {
        Write-output "Checking for $name" 
        foreach ($agent in $agentManagedComputers) {
            if ($deleteCollection -eq $null) {
                $deleteCollection = new-collection $agent.GetType()
            }
                    
            if (@($agent.PrincipalName -match $name)) {
                Write-output "Matched $name"
                $deleteCollection.Add($agent)
                break
            }
        }
    }

    if ($deleteCollection.Count -gt 0) {
        Write-output "Deleting agents"
        $admin.DeleteAgentManagedComputers($deleteCollection)
        if ($?) { Write-output "Agents deleted" }
        Write-output "Deleted: "$($deleteCollection.DisplayName)
    }
}
