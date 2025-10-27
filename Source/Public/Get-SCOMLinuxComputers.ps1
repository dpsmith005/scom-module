Function Get-SCOMLinuxComputers {
    <#
    .Synopsis
    Get the SCOM Linux servers
    .Description
    Return the linux computer class instances
    .Example
    Get-SCOMLinuxComputers
    provides a list of the linux computers class
    .Notes
    NAME:     Get-SCOMLinuxComputers
    AUTHOR:   David Smith
    LASTEDIT: 27 April 2025
    #Requires -Version 5.0
    #>

    Get-SCOMClass -Name "Microsoft.Linux.Computer" | Get-SCOMClassInstance
}