Function Get-SCOMNodes {
    <#
    .Synopsis
    Get the SCOM Nodes
    .Description
    Return the node class instances
    .Example
    Get-SCOMNodes
    provides a list of the nodes class
    .Notes
    NAME:     Get-SCOMNodes
    AUTHOR:   David Smith
    LASTEDIT: 27 April 2025
    #>
    #Requires -Version 5.0    
    Get-SCOMClass -DisplayName node | Get-SCOMClassInstance
}