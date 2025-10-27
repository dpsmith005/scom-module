function Get-SCOMClassInstancesByDisplayName () {
    <#
.Synopsis

  .Description
    Retrieve the classes of the specified name
  .Parameter DisplayName
    This will look and the class instance displayname for the specified regular expression.
  .Example
    Get-SCOMClassInstancesByDisplayName test00
    Supply the agent name or regular expression you want to match and find all classes that agent belongs.
  .Example
    Get-SCOMClassInstancesByDisplayName test
    get all classes that match anything with test
.Notes
    NAME:     Get-SCOMClassInstancesByDisplayName
    AUTHOR:   David Smith
    LASTEDIT: 20 October 2025
    KEYWORDS:
  #Requires -Version 5.0
#>
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][string]$DisplayName)

    If ($PSBoundParameters.ContainsKey('Debug')) {
        $DebugPreference = 'Continue'
    }
    Write-Debug "Beginning to search for displayname in classes..."

    # list all classes a where a specific agent is a member
    $arr2 = @()
    $classes = get-SCOMClass    # -DisplayName "Windows Computer"
    $totalItems = $classes.count
    $ct = 0
    foreach ($class in $classes) {
        $ct++
        Write-Progress -Activity "Processing classes" -Status "Working on class $($class.DisplayName)  $ct of $totalItems" -PercentComplete (($ct / $totalItems) * 100) -CurrentOperation "Processing item $ct"
        foreach ($instance in (Get-SCOMClassInstance -Class $class)) {
            if ($instance.DisplayName -match "$DisplayName") {
                $arr2 += [PSCustomObject]@{
                    Name             = $instance.Name;
                    Path             = $instance.Path;
                    DisplayName      = $instance.DisplayName;
                    FullName         = $instance.FullName
                    ClassDisplayName = $class.DisplayName;
                    ClassName        = $class.Name;
                }
            }
        }
    }
    $arr2

    Write-Debug "Completed search."
}
