#Connect to SCOM DEV ()
Function Connect-SCOMDev {
    <#
.SYNOPSIS
    Connect to SCOM old Development environment WSHDEV
.DESCRIPTION
    Connect to SCOM old Development environment WSHDEV
.EXAMPLE
    Connect-SCOMDev
	This will connect to the SCOM management group WSHDEV
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
