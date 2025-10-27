Function Get-SCOMResourcePoolMembers {
    <#
    .Synopsis
    Get the SCOM Resource pool members
    .Description
    Return a list of resource pool members based on supplied resource pool name.  The resource pool name can be a regular expression.
    Will list all resource pools and members using the -List switch.
    Debug option is enabled for this cmdlet.
    .PARAMETER ResourcePool
    This parameter is used to retrieve the members of a specified resource pool
    .PARAMETER List
    This is a switch that will list all members of all resource pools
    .Example
    Get-SCOMResourcePoolMembers ResourcePoolDisplayName
    Returns a list of pool members and which is active
    .Example
    Get-SCOMResourcePoolMembers -List
    Returns a list of all resouce pools and their members
    .Example
    (Get-SCOMResourcePool | ? { $_.Displayname -match "Notif" } | select -ExpandProperty members | ? { $_.IsAvailable -eq $false }).DisplayName
    This is a one-liner to get the active member of the current notification pool
    .Notes
    NAME:     Get-SCOMResourcePoolMembers
    AUTHOR:   David Smith
    LASTEDIT: 23 October 2025
        (Get-SCOMResourcePool | ? { $_.Displayname -match "Notif" } | select -ExpandProperty members | ? { $_.IsAvailable -eq $false }).DisplayName
    #>
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Pool")][string]$ResourcePool,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "List")][switch]$List
    )

    If ($PSBoundParameters.ContainsKey('Debug')) {
        $DebugPreference = 'Continue'
    }

    $resourcePools = Get-SCOMResourcePool
    $arr = @()

    if ($PSCmdlet.ParameterSetName -eq "Pool") {
        Write-Debug "Action based on Resource Pool: $ResourcePool"
        $rps = $resourcePools | Where-Object { $_.Displayname -match "$ResourcePool" }
        foreach ($rp in $rps) {
            foreach ($member in $rp.Members) {
                if ($member.IsAvailable -eq $true) {
                    $IsActive = $false

                }
                elseif ($member.IsAvailable -eq $false) {
                    $IsActive = $true
                }
                Write-Debug "$($rp.DisplayName) $($member.DisplayName) IsActive $IsActive"
                $arr += [PSCustomObject]@{
                    ResourcePool = $rp.DisplayName
                    Name         = $member.DisplayName
                    IsActive     = $IsActive
                    #IsAvailable  = $member.IsAvailable
                }
            }
        }

    }
    elseif ($PSCmdlet.ParameterSetName -eq "List") {
        Write-Debug "Action based on List: $List"
        foreach ($rp in $resourcePools) {
            Write-Debug "Processing pool $($rp.DisplayName)"
            foreach ($member in $rp.Members) {
                if ($member.IsAvailable -eq $true) {
                    $IsActive = $false

                }
                elseif ($member.IsAvailable -eq $false) {
                    $IsActive = $true
                }
                Write-Debug "$($rp.DisplayName) $($member.DisplayName) IsActive $IsActive"
                $arr += [PSCustomObject]@{
                    ResourcePool = $rp.DisplayName
                    Name         = $member.DisplayName
                    IsActive     = $IsActive
                    #IsAvailable  = $member.IsAvailable
                }
            }
        }
    }
    $arr
}
