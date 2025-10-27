function Get-RemoteRegistryPathValues {
    <#
  .Synopsis
    Retrieve a remote registry value
  .Description
    Run this function to retrieve a specific registry value
  .Parameter ComputerName
    Name of the Windows computer to query
  .Parameter RegistryPath
    Registry key where the value is stored
  .Parameter Credential
    provide credentials is needed
  .Example
    $Credential = Get-Credential
    $ServerName = "Test00"
    Get-RemoteRegistryPathValues -ComputerName $ServerName -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Credential $Credential

    Supply the computer name, registry path, and the credentails
  .Example
    $ComputerName="computer01"
    Get-RemoteRegistryPathValues -ComputerName $ComputerName -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

    Supply the computer name and registry path.  No credentials supplied, uses the credentials of the current user.
.Example
    "computer01","computer02" | Get-RemoteRegistryPathValues  -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

    Pass the computer names through a pipeline to return the registry values
.Example
    $ComputerName="computer01"
    Get-RemoteRegistryPathValues $ComputerName  "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

    Process the parameters based on the order
.Notes
    NAME:     Get-RemoteRegistryPathValues
    AUTHOR:   David Smith
    LASTEDIT: 15 October 2025
    KEYWORDS:
  #Requires -Version 5.0
#>
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][string]$ComputerName,
        [Parameter(Mandatory = $true, Position = 1)][string]$RegistryPath,
        [Parameter(Position = 2)][System.Management.Automation.PSCredential]$Credential
    )
    begin {
        If ($PSBoundParameters.ContainsKey('Debug')) {
            $DebugPreference = 'Continue'
        }
    }

    process {
        if (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
            try {
                # Check if the credentials were supplied
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $data = Invoke-Command -ScriptBlock { param($regPath); Get-ItemProperty -Path "$regPath" } -ComputerName $ComputerName -ArgumentList $RegistryPath -Credential $Credential
                }
                else {
                    $data = Invoke-Command -ScriptBlock { param($regPath); Get-ItemProperty -Path "$regPath" } -ComputerName $ComputerName -ArgumentList $RegistryPath
                }
                $arrOut = @()
                $properties = $data | Get-Member -MemberType NoteProperty | Select-Object Name | where-object { $_.Name -notmatch "^PS" } | % { $n = $_.name; "$n" }   # : $($d.$n)"}
                $properties | ForEach-Object {
                    $property = $_
                    $value = $data.($property.Trim())
                    $myCustomObject = [PSCustomObject]@{
                        ComputerName = $ComputerName
                        registryPath = $registryPath
                        Property     = $property
                        Value        = $value
                    }
                    $arrOut += $myCustomObject
                }
            }
            catch {
                $myCustomObject = [PSCustomObject]@{
                    ComputerName = $ComputerName
                    registryPath = $registryPath
                    Property     = $RegistryPath
                    Value        = "No Value Found"
                }
                $arrOut += $myCustomObject
                Write-Host "Error detected : $($Error[0])"
            }
        }
        else {
            Write-Warning "The Computer is not reachable $ComputerName"
            $myCustomObject = [PSCustomObject]@{
                ComputerName = $ComputerName
                registryPath = $registryPath
                Property     = $RegistryPath
                Value        = "Computer NOT found"
            }
            $arrOut += $myCustomObject
        }
        $arrOut
    }

    end { }
}
