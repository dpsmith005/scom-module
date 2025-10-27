function Get-NetFramework {
	<#
.SYNOPSIS
    This Script will retrieve the .Net framework information
.DESCRIPTION
    This script will pool the specivied server to get the .NET framework information from that server.
	This command accepts items from the pipline to process multiple items
.PARAMETER server   
    This is the server name to check the .NET framework
.EXAMPLE
    Get-NetFramework server
	Gather the .Net framework info from the server
.EXAMPLE
    "tsmgr2","tsmgr3","test" | Get-NetFramework
    This will pipe the servers to gather the .NET Framework info
.NOTES
    Version:        1.2
    Author:         David Smith
    Creation Date:  9 July 2025
    Updated Date:   9 July 2025 by David Smith
    Purpose/Change: Initial script development for shared scripts
    Created this script to gahter .NET Framework info
#>
	Param([Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][string]$server)
    
	Begin { $timer = [system.diagnostics.stopwatch]::StartNew() }

	Process {
		if (test-connection $server -Quiet -Count 1) {
			$results = invoke-command -ScriptBlock { get-itemproperty "hklm:\Software\Microsoft\Net Framework setup\NDP\v4\Full" } -ComputerName $server -ea 0
			if ($?) {
				$Release = $results.Release
				$Version = $results.Version
			}
			else {
				$Release = 0
				$Version = "Unable to retrieve remote registry"
			} 
		}
		else {
			$Release = 00
			$Version = "unavailable"
		}
		$computer = get-scomclassinstance -Class ( Get-SCOMClass -Name Microsoft.Windows.Computer) | ? { $_.DisplayName -match $server }
		$IsManaged = $computer.IsManaged
		$IsAvailable = $computer.IsAvailable
		$InMaintenanceMode = $computer.InMaintenanceMode
		$HealthState = $computer.HealthState
		$data = [PSCustomObject]@{Server = $server; Release = $Release; Version = $Version; IsManaged = $IsManaged; IsAvailable = $IsAvailable; InMM = $InMaintenanceMode; HealthState = $HealthState }
		$data
	}

	End {
		$timer.Stop()
		$totalElapsedTime = "{0:HH:mm:ss}" -f ([datetime]$timer.ElapsedTicks)
		#Write-Host Total elapsed time : $totalElapsedTime
	}
}	
 
<#
 Switch($Release) {
"378389" { return ".NET Framework 4.5" }
"378675" { return ".NET Framework 4.5.1" }
"379893" { return ".NET Framework 4.5.2" }
"393295" { return ".NET Framework 4.6" }
"393297" { return ".NET Framework 4.6" }
"394254" { return ".NET Framework 4.6.1" }
"394271" { return ".NET Framework 4.6.1" }
"394802" { return ".NET Framework 4.6.2" }
"394806" { return ".NET Framework 4.6.2" }
"460798" { return ".NET Framework 4.7" }
"460805" { return ".NET Framework 4.7" }
"461308" { return ".NET Framework 4.7.1" }
"461310" { return ".NET Framework 4.7.1" }
"461808" { return ".NET Framework 4.7.2" }
"461814" { return ".NET Framework 4.7.2" }
"528040" { return ".NET Framework 4.8" }
"528049" { return ".NET Framework 4.8" }
}
#>