#Connect to SCOM DEV ()
Function Connect-SCOM {
    <#
    .SYNOPSIS
    Connect to SCOM
    .DESCRIPTION
    Connect to SCOM by selecting from a list of SCOM management servers stored in a text file
    The list of management servers is stored in $env:TMP\mgtservers.txt
    .PARAMETER Select
    Displays the
    .PARAMETER Edit
    This paramter will run notepad to create the file if it does not exist.
    If the file exists it will open the file in notepad to edit.
    Management Servers should be stored in the file one server per line.
    .EXAMPLE
    Connect-SCOM
	This will present a list of SCOM Management Servers.  Select a server to connect to the SCOM management group.
    .NOTES
    Version:        1.0
    Author:         David Smith
    Creation Date:  9 July 2025
    Updated Date:   20 October 2025 by David Smith
    Purpose/Change: Initial script development for shared scripts
#>
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Select")][switch]$Select,
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Edit")][switch]$Edit
    )

    If ($PSBoundParameters.ContainsKey('Debug')) {
        $DebugPreference = 'Continue'
    }

    $file = $env:TMP + "\mgtservers.txt"
    $fileExists = Test-Path $file

    if ($PSCmdlet.ParameterSetName -eq "Edit") {
        # Edit the test file to store the management servers (Use notepad)
        Write-Debug "Opening the file $file with notepad.exe"
        notepad.exe $file
    }
    elseif ($PSCmdlet.ParameterSetName -eq "Select") {
        # Display the menu of available management servers for selection
        if ($fileExists) {
            Write-Debug "File exists.  Reading the file and displaying the menu"
            $data = Get-Content $file

            # Display the list of management servers
            Clear-Host
            Write-Host "----- Management Server Selections -----"
            for ($i = 0; $i -lt $data.count; $i++) { "$($i+1). $($data[$i])" }
            Write-Host ""
            do {
                $choice = Read-Host "Enter the selection number (1-$($data.count))"
                if ($choice -match '^\d$' -and $choice -lt $data.count -and $choice -ne 0) {
                    $isValid = $true
                }
                else {
                    $isValid = $false
                }
            } while (-not $isValid)
            Write-Debug "The choice entered is $choice"
            $MSComputer = $data[$($choice - 1)]
            if ([int]$choice -gt $data.count) {
                Write-Error "Invalid selection"
            }
            Write-Debug "Connecting to management server $MSComputer"
            new-SCOMManagementGroupConnection -ComputerName $MSComputer
            Get-SCOMManagementGroupConnection | Select-Object ManagementServerName, ManagementGroupName, IsActive, @{N = "Version"; E = { (Get-SCOMManagementGroup).Version } }
        }
        else {
            Write-Host "The file $file does not exist.  Use the -Create option to create this file"
        }

    }



}
