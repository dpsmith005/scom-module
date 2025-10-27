function Get-SCOMAgentWorkflow() {
    <#
.Synopsis
Get the workflows for the specified agent
.Description
Returns the monitor, rules, and discoveries for the specified SCOM agent
.Parameter agentname
name of the SCOM agent
.Example
Get-SCOMAgentWorkflow -agentname test00
Provides the monitors, rules, and discoveries for the specified agent.
.Notes
NAME:     Get-SCOMLinuxComputers
AUTHOR:   David Smith
LASTEDIT: 27 April 2025
#Requires -Version 5.0
#>
    param([Parameter(Mandatory = $true)][string]$agentname)
    #Original Script from Jeremy Pavleck.
    #http://www.pavleck.net/2008/06/sp1-gem-finding-rules-running-on-remote-agents/
    $DEBUG = $false

    #Use the OpsMgr Task Show Running Rules and Monitors.
    $taskobj = Get-SCOMTask | Where-Object { $_.Name -eq "Microsoft.SystemCenter.GetAllRunningWorkflows" }

    # Grab HealthService class object
    $hsobj = Get-SCOMClass -name "Microsoft.SystemCenter.HealthService"
    # Find HealthService object defined for named server
    $monobj = Get-SCOMMonitoringObject -Class $hsobj | Where-Object { $_.DisplayName -match $agentname }

    #Start Task GetAllRunningWorkflows
    $taskOut = Start-SCOMTask -Task $taskobj -Instance $monobj -TaskCredentiaLS $NULL
    while ((Get-SCOMTaskResult -BatchID $taskOut.BatchId).Status -ne "Succeeded") { Write-Host Get Results Waiting...; Start-Sleep 1 }  # Wait for task to complete
    Write-Host "Get Results Completed"
    [xml]$taskXML = (Get-SCOMTaskResult -BatchID $taskOut.BatchId).Output

    #Get Workflows
    $workflows = $taskXML.selectnodes("/DataItem/Details/Instance/Workflow")

    #Retrieve Monitors
    $monitors = get-SCOMmonitor

    #Retrieve Rules
    $rules = get-SCOMrule

    #Retrieve Discoveries"
    #Used the Group-object because there are some discovery rules with the same DisplayName
    $discoveries = get-SCOMdiscovery | select-object -Unique

    #Get Overrides"
    #monitoroverrides = foreach ($monitor in Get-ManagementPack | get-override | where {$_.monitor}) {get-monitor | where {$_.Id -eq $monitor.monitor.id}}
    #$rulesoverrides = foreach ($rule in Get-ManagementPack | get-override | where {$_.rule}) {get-rule | where {$_.Id -eq $rule.rule.id}}
    #$discoveryoverrides = foreach ($discovery in Get-ManagementPack | get-override | where {$_.discovery}) {get-discovery | where {$_.Id -eq $discovery.discovery.id}}
    class record {
        [string]$Type
        [string]$MPDisplayName
        [string]$DisplayName
        [string]$Description

    }

    #Check for each workflow if it's a Rule or Monitor or Discovery.
    if ($DEBUG) { Write-Host Processing workflows }
    $arrOut = @()
    foreach ($workflow in ($workflows | Sort-Object '#text') ) {
        $items = [record]::new()
        if ($DEBUG) { Write-Host $workflow."#text" }
        #Check for Monitor
        $monitor = $monitors | where-object { $_.Name -eq $workflow."#text" }
        #$monitor = $workflow."#text" | Get-SCOMMonitor -ea 0
        if ($null -eq $monitor) {
            #Check for Rule (It's not a monitor)
            $rule = $rules | where-object { $_.Name -eq $workflow."#text" }
            #$rule = $workflow."#text" | Get-SCOMRule -ea 0
            if ($null -eq $rule) {
                #Check for Discovery  (It's not a rule)
                $discovery = $discoveries | where-object { $_.Name -eq $workflow."#text" }
                #$discovery = $workflow."#text" | Get-SCOMDiscovery -ea 0
                if ($null -eq $discovery) {
                    # It is not a Discovery Rule or Monitor
                    #if ($DEBUG) {Write-Host None $workflow."#text"}
                    $items.Type = "none"
                    $items.DisplayName = ""
                    $items.Description = ""
                    $items.MPDisplayName = ""
                    #$arrOut += $items
                }
                else {
                    if ($DEBUG) { Write-Host Discovery $discovery.DisplayName }
                    $items.Type = "Discovery"
                    #Get ManagementPack
                    $mp = $discovery.getmanagementpack()
                    $items.DisplayName = $discovery.DisplayName
                    $items.Description = $discovery.Description
                    $items.MPDisplayName = $mp.DisplayName
                    $arrOut += $items
                    #if ([string]::IsNullOrEmpty($discovery.DisplayName)) { return }
                } # End of Discovery Check
            }
            else {
                if ($DEBUG) { Write-Host Rule $rule.DisplayName }
                $items.Type = "Rule"
                $mp = $rule.getmanagementpack()
                $items.DisplayName = $rule.DisplayName
                $items.Description = $rule.Description
                $items.MPDisplayName = $mp.DisplayName
                $arrOut += $items
            } # End of Rule Check
        }
        else {
            if ($DEBUG) { Write-Host Monitor $monitor.DisplayName }
            $items.Type = "Monitor"
            $mp = $monitor.getmanagementpack()
            $items.DisplayName = $monitor.DisplayName
            $items.Description = $monitor.Description
            $items.MPDisplayName = $mp.DisplayName
            $arrOut += $items
        } # End of Monitor Check

        Remove-Variable monitor, rule, discovery, items -ErrorAction SilentlyContinue
    } # End of foreach $workflows
    return $arrOut

} # End Function
