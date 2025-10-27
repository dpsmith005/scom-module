function Get-SCOMClassInstancesByFullName () {
    <#
.Synopsis

  .Description
    Retrieve the classes of the specified name
  .Parameter FullName
    This will look and the class instance fullname for the specified regular expression.
  .Example
    Get-SCOMClassInstancesByFullName test00
    Supply the agent name or regular expression you want to match and find all classes that agent belongs.
  .Example
    Get-SCOMClassInstancesByFullName test
    get all classes that match anything with test
.Notes
    NAME:     Get-SCOMClassInstancesByFullName
    AUTHOR:   David Smith
    LASTEDIT: 20 October 2025
    KEYWORDS:
  #Requires -Version 5.0
#>
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][string]$FullName)

    If ($PSBoundParameters.ContainsKey('Debug')) {
        $DebugPreference = 'Continue'
    }

    Write-Debug "Beginning to search for fullname in classes..."

    # list all classes a where a specific agent is a member
    $arr = @()
    $classes = get-SCOMClass    # -DisplayName "Windows Computer"
    $totalItems = $classes.count
    $ct = 0
    #foreach ($class in Get-SCOMclass) { Get-SCOMClassInstance -Class $class | ForEach-Object { if ($_.FullName -match "tsmgr4") { $arr += [PSCustomObject]@{FullName = $_.FullName; Class = $class.DisplayName } } } }
    foreach ($class in (Get-SCOMclass -displayname "Windows Computer")) {
        $ct++
        Write-Progress -Activity "Processing classes" -Status "Working on class $($class.DisplayName)  $ct of $totalItems" -PercentComplete (($ct / $totalItems) * 100) -CurrentOperation "Processing item $ct"
        foreach ($instance in (Get-SCOMClassInstance -Class $class)) {
            if ($instance.DisplayName -match "$DisplayName") {
                $arr += [PSCustomObject]@{
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
    $arr

    Write-Debug "Completed search."
}
