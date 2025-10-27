function Clear-SCOMHealthService {
    <#
.SYNOPSIS
    This Script will flush the SCOM agent
.DESCRIPTION
    This script will stop the SCOM Monitoring Agent, delete the HealthService folder and restart the agent.
.PARAMETER server   
    This is the server name to flush the health service
.EXAMPLE
    Clean-SCOMAgentHeelthService server
	This will flush the health state on the specified server
.EXAMPLE
    "tsmgr2","tsmgr3","test" | Clear-SCOMHealthService
    This will pipe the servers to flush the health state
.NOTES
    Version:        1.2
    Author:         David Smith
    Creation Date:  9 July 2025
    Updated Date:   9 July 2025 by David Smith
    Purpose/Change: Initial script development for shared scripts
    Created this script to be used to flush the SCOM Monitoring Agent
#>
    Param([Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][string]$server)
    
    Begin {}
    Process {
        # Test the network connection
        if (!(test-connection $server -Count 1 -ea 0)) { 
            Write-Host Unable to connect to $server
            return
        } 

        # Get the Health Service process path
        $process = Invoke-Command -ScriptBlock { Get-Process -Name HealthService } -ComputerName $server
        $path = $process.Path | Split-Path
        $path += "\Health Service State"

        # Stop Service -  Health Service State
        Get-Service -Name "Microsoft Monitoring Agent" -ComputerName $server | Stop-Service
        start-sleep -Seconds 5

        # remove  Health Service State folder
        $out = Invoke-Command -ComputerName $server -ScriptBlock { param($p); if (test-path $p) { Remove-Item -Path $p -Recurse -Confirm:$false; } } -ArgumentList $path 2>&1
        if ($out.ErrorDetails.Message -match "Cannot remove item") {
            Write-Host "Unable to remove Health Service State folder on $server" -ForegroundColor DarkRed
        }
        else {
            Write-Host "Removed Health Service State folder on $server" -ForegroundColor Green
        }

        # Start service -  Health Service State
        Get-Service -Name "Microsoft Monitoring Agent" -ComputerName $server | Start-Service
        start-sleep -Seconds 5

        # Verify Service started
        if ((Get-Service -Name "Microsoft Monitoring Agent" -ComputerName $server).Status -eq "Running") {
            Write-Host Microsoft Monitoring Agent is running on $server -ForegroundColor Green
        }
        else {
            Write-Host Microsoft Monitoring Agent is NOT running on $server -ForegroundColor DarkRed
        }
    }
    End {}
}
