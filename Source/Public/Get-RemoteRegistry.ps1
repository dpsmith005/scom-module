function Get-RemoteRegistry {
    <#
  .Synopsis
    Retrieve a remote registry value
  .Description
    Run this function to retrieve a specific registry value.  Aletrnate credentials are optional.
    There is a Get-RemoteRegistryFast that runs much faster, but does not support alternate credentials.
  .Parameter ComputerName
    Name of the Windows computer to query
  .Parameter RegistryPath
    Registry key where the value is stored
  .Parameter RegistryValue
    The registry value to return
  .Parameter Credential
    provide credentials is needed
  .Example
    $Credential = Get-Credential
    $ServerName = "Test00"
    Get-RemoteRegistry -ComputerName $ServerName -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -RegistryValue "ProductName" -Credential $Credential

    Supply the computer name, registry path, registry value and the credentails
  .Example
    $ComputerName="computer01"
    Get-RemoteRegistry -ComputerName $ComputerName -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -RegistryValue "ProductName"

    Supply the computer name, registry path, and registry value.  No credentials supplied, uses the credentials of the current user.
.Example
    "computer01","computer02" | Get-RemoteRegistry  -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -RegistryValue "ProductName"

    Pass the computer names through a pipeline
.Example
    $ComputerName="computer01"
    Get-RemoteRegistry $ComputerName  "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"  "ProductName"

    Process the parameters based on the order
.Notes
    NAME:     Get-RemoteRegistry
    AUTHOR:   David Smith
    LASTEDIT: 14 October 2025
    KEYWORDS:
  #Requires -Version 5.0
#>
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][string]$ComputerName,
        [Parameter(Mandatory = $true, Position = 1)][string]$RegistryPath,
        [Parameter(Mandatory = $true, Position = 2)][string]$RegistryValue,
        [Parameter(Mandatory = $false, Position = 3)][System.Management.Automation.PSCredential]$Credential
    )
    begin {
        If ($PSBoundParameters.ContainsKey('Debug')) {
            $DebugPreference = 'Continue'
        }
    }

    process {
        $arrOut = @()
        if (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
            try {
                # Check if the credentials were supplied
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    Write-Debug "Running with passed credentials"
                    $value = Invoke-Command -ScriptBlock { param($regPath, $regName); Get-ItemProperty -Path "$regPath" -Name $regName } -ComputerName $ComputerName -ArgumentList $RegistryPath, $RegistryValue -Credential $Credential -ErrorAction SilentlyContinue
                }
                else {
                    Write-Debug "Running without credentials"
                    $value = Invoke-Command -ScriptBlock { param($regPath, $regName); Get-ItemProperty -Path "$regPath" -Name $regName } -ComputerName $ComputerName -ArgumentList $RegistryPath, $RegistryValue -ErrorAction SilentlyContinue
                }
                if (!$?) {
                    Write-Warning "Invoke-command failed to retrieve registry data"
                    $myCustomObject = [PSCustomObject]@{
                        ComputerName  = $ComputerName
                        registryPath  = $registryPath
                        RegistryName  = $RegistryValue
                        RegistryValue = "Failed to retrieve registry data"
                    }
                }
                else {
                    $myCustomObject = [PSCustomObject]@{
                        ComputerName  = $ComputerName
                        registryPath  = $registryPath
                        RegistryName  = $RegistryValue
                        RegistryValue = $value.$RegistryValue
                    }
                }
                $arrOut += $myCustomObject
            }
            catch {
                $myCustomObject = [PSCustomObject]@{
                    ComputerName  = $ComputerName
                    registryPath  = $registryPath
                    RegistryName  = $RegistryValue
                    RegistryValue = "No Value Found"
                }
                $arrOut += $myCustomObject
            }
        }
        else {
            Write-Warning "The Computer is not reachable $ComputerName"
            $myCustomObject = [PSCustomObject]@{
                ComputerName  = $ComputerName
                registryPath  = $registryPath
                RegistryName  = $RegistryValue
                RegistryValue = "Computer NOT found"
            }
            $arrOut += $myCustomObject
        }
        $arrOut
    }
}
