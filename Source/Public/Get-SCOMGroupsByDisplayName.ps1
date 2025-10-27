function Get-SCOMGroupsByDisplayName () {
    <#
.Synopsis

  .Description
    Retrieve the classes of the specified name
  .Parameter ComputerName
    This will look at all groups for the specified system name
  .Example
    Get-SCOMGroupsByDisplayName test*00
    Supply the agent name or regular expression you want to match and find all groups that agent belongs.
  .Example
    Get-SCOMGroupsByDisplayName test
    get all groups that match anything with test
.Notes
    NAME:     Get-SCOMGroupsByDisplayName
    AUTHOR:   David Smith
    LASTEDIT: 20 October 2025
    KEYWORDS:
  #Requires -Version 5.0
#>
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][string]$ComputerName)

    If ($PSBoundParameters.ContainsKey('Debug')) {
        $DebugPreference = 'Continue'
    }
    Write-Debug "Beginning to search for server name in all groups..."

    # list all groups a where a specific agent is a member
    $groups = get-SCOMGroup
    $totalItems = $groups.count
    $ct = 0
    foreach ($group in $groups) {
        $ct++
        Write-Progress -Activity "Processing Groups" -Status "Working on group $($group.DisplayName) $ct of $totalItems" -PercentComplete (($ct / $totalItems) * 100) -CurrentOperation "Processing item $ct"
        foreach ($instance in ($group | Get-SCOMClassInstance)) {
            if ($instance.Displayname -match "$ComputerName") {
                $group.DisplayName
            }
        }
    }

    Write-Debug "Completed search."
}
