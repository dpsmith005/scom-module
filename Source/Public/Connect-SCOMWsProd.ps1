#Connect to SCOM PROD (WSPROD)
Function Connect-SCOMWsProd {
    <#
.SYNOPSIS
    Connect to SCOM Production environment WSPROD
.DESCRIPTION
    Connect to SCOM production environment WSPROD
.EXAMPLE
    Connect-SCOMDev
	This will connect to the SCOM management group WSPROD
.NOTES
    Version:        1.0
    Author:         David Smith
    Creation Date:  9 July 2025
    Updated Date:   20 October 2025 by David Smith
    Purpose/Change: Initial script development for shared scripts
#>
    $MSComputer = "scomms07.wellspan.org"
    new-SCOMManagementGroupConnection -ComputerName $MSComputer
    Get-SCOMManagementGroup | Select-Object Name, IsConnected, Version
}
