#Connect to SCOM DEV (WSDEV)
Function Connect-SCOMWsDev {
    <#
.SYNOPSIS
    Connect to SCOM Development environment WSDEV
.DESCRIPTION
    Connect to SCOM Development environment WSDEV
.EXAMPLE
    Connect-SCOMDev
	This will connect to the SCOM management group WSDEV
.NOTES
    Version:        1.0
    Author:         David Smith
    Creation Date:  9 July 2025
    Updated Date:   20 October 2025 by David Smith
    Purpose/Change: Initial script development for shared scripts
#>
    $MSComputer = "scomtst02.wellspan.org"
    new-SCOMManagementGroupConnection -ComputerName $MSComputer
    Get-SCOMManagementGroup | Select-Object Name, IsConnected, Version
}
