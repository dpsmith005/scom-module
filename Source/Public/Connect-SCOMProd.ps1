#Connect to SCOM PROD (WSHPROD)
Function Connect-SCOMProd {
    <#
.SYNOPSIS
    Connect to SCOM old Production environment WSHPROD
.DESCRIPTION
    Connect to SCOM old Production environment WSHPROD
.EXAMPLE
    Connect-SCOMDev
	This will connect to the SCOM management group WSHPROD
.NOTES
    Version:        1.0
    Author:         David Smith
    Creation Date:  9 July 2025
    Updated Date:   20 October 2025 by David Smith
    Purpose/Change: Initial script development for shared scripts
#>
    $MSComputer = "scomms01.wellspan.org"
    new-SCOMManagementGroupConnection -ComputerName $MSComputer
    Get-SCOMManagementGroup | Select-Object Name, IsConnected, Version
}
