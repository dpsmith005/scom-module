Function Get-SCOMWindowsComputers {
    <#
    .Synopsis
    Get the SCOM Windows servers
    .Description
    Return the windows computer class instances
    .Example
    Get-SCOMWindowsComputers
    provides a list of the windows computers class
    .Notes
    NAME:     Get-SCOMWindowsComputers
    AUTHOR:   David Smith
    LASTEDIT: 27 April 2025
    #>
    #Requires -Version 5.0    
    Get-SCOMClass -Name "Microsoft.Windows.Computer" | Get-SCOMClassInstance
}