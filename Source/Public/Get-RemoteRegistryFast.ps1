function Get-RemoteRegistryFast {
    <#
  .Synopsis
    Retrieve a remote registry value
  .Description
    Run this function to retrieve a specific registry value.  The valid Hives are HKLM (Local Machine) or HKCU (Current User).
    This cmdlet does not use specified credentials.  Open a powershell window with an account that has permissions to the registry.
  .Parameter ComputerName
    Name of the Windows computer to query
  .Parameter RegistryPath
    Registry path where the value is stored.  HLKM:\<path to registry value> or HKCU:\<path to registry value>
  .Parameter RegistryValue
    The registry value to return.  This is optional.  If not supplied, returns all values in the registry path.
  .Example
    $ServerName = "Test00"
    Get-RemoteRegistryFast -ComputerName $ComputerName -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -RegistryValue "ProductName"

    Supply the computer name, registry path, registry value and the credentails
    To run this with different credentials open a powershell window with those credentials
    From the existing powershell windows run: runas /user:<domain\user> "powershell.exe"
  .Example
    $ComputerName="computer01"
    Get-RemoteRegistryFast -ComputerName $ComputerName  -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -RegistryValue "ProductName"

    Supply the computer name, registry path, and registry value. Uses the credentials of the current user.
.Example
    "computer01","computer02" | Get-RemoteRegistryFast -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -RegistryValue "ProductName"

    Pass the computer names through a pipeline
.Example
    $ComputerName="computer01"
    Get-RemoteRegistryFast $ComputerName  HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion"  "ProductName"

    Process the parameters based on the order
.Notes
    NAME:     Get-RemoteRegistryFast
    AUTHOR:   David Smith
    LASTEDIT: 15 October 2025
    KEYWORDS:
  #Requires -Version 5.0
#>
    [CmdletBinding()]
    Param([Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][string]$ComputerName,
        [Parameter(Mandatory = $true, Position = 2)][string]$RegistryPath,
        [Parameter(Mandatory = $false, Position = 3)][string]$RegistryValue

    )
    begin {
        If ($PSBoundParameters.ContainsKey('Debug')) {
            $DebugPreference = 'Continue'
        }
        # Check if registry value supplied.  If not get all path values
        if ($PSBoundParameters.ContainsKey('RegistryValue')) {
            $GETPATH = $false
            Write-Debug "Get single value"
        }
        else {
            $GETPATH = $true
            Write-Debug "Get all path values"
        }
        # Get the hive type from the registry path
        $hkey, $path = $RegistryPath.split(":")
        $regPath = $path.Substring(1, ($path.length - 1))
    }

    process {
        Write-Debug "Processing $ComputerName"
        $arrOut = @()
        try {
            if (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
                # Retrieve the registry values
                $prevErrAct = $ErrorActionPreference
                $ErrorActionPreference = "SilentlyContinue"
                $reg = Get-WmiObject -List -Namespace root\default -ComputerName $ComputerName -Credential $cred | Where-Object { $_.Name -eq "StdRegProv" }
                $HKLM = 2147483650  # HKey Local Machine
                $HKCU = 2147483649   # HKey Current User
                if ($hkey -eq "HKCU") {
                    $RegHive = $HKCU
                } if ($hkey -eq "HKLM") {
                    $RegHive = $HKLM
                }
                else {
                    Write-Error "The only valid registry hives are HKLM and HKLU"
                }
                if ($GETPATH) {
                    # Get all registry values in specified reg path
                    $regValues = $reg.EnumValues($reghive, "$regPath").sNames
                    Write-Debug "Retrieved all values in registry path"
                    if ($null -eq $regValues) {
                        Write-Warning "The registry path or key does not exists $RegistryPath $RegistryValue"
                        $myCustomObject = [PSCustomObject]@{
                            ComputerName  = $ComputerName
                            registryPath  = $registryPath
                            RegistryName  = $RegistryValue
                            RegistryValue = "No Values Found in path"
                        }
                        $arrOut += $myCustomObject
                        Write-Debug "No values for path found on $ComputerName"
                    }
                    else {
                        foreach ($rv in $regValues) {
                            $value = $reg.GetStringValue($RegHive, "$regPath", $rv).sValue
                            $myCustomObject = [PSCustomObject]@{
                                ComputerName  = $reg.PSComputerName
                                registryPath  = $registryPath
                                RegistryName  = $rv
                                RegistryValue = $value
                            }
                            $arrOut += $myCustomObject
                            Write-Debug "Found value on $ComputerName. $rv : $value"
                        }
                    }
                }
                else {
                    $regValue = $reg.GetStringValue($RegHive, "$regPath", "$RegistryValue").sValue
                    if ($null -eq $regValue) {
                        Write-Warning "The registry path or key does not exists $RegistryPath $RegistryValue"
                        $myCustomObject = [PSCustomObject]@{
                            ComputerName  = $ComputerName
                            registryPath  = $registryPath
                            RegistryName  = $RegistryValue
                            RegistryValue = "No Value Found"
                        }
                        Write-Debug "No value found on $ComputerName"
                    }
                    else {
                        $regValue = $reg.GetStringValue($RegHive, "$regPath", "$RegistryValue").sValue
                        $myCustomObject = [PSCustomObject]@{
                            ComputerName  = $reg.PSComputerName
                            registryPath  = $registryPath
                            RegistryName  = $RegistryValue
                            RegistryValue = $regValue
                        }
                        Write-Debug "Found value on $ComputerName"
                    }
                    $arrOut += $myCustomObject
                    $ErrorActionPreference = $prevErrAct
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
                Write-Debug "$ComputerName not found"
                $arrOut += $myCustomObject
            }
        }
        catch {
            Write-Error "An error occurred: $($_.Exception.Message)"
        }
        $arrOut
    }
}
