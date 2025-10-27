# SCOM Module

## Installation

```powershell
Install-Module -Name Wellspan.SCOM
```

This module is stored in a local repository -  http://tsmgr4.wellspan.org:8080/nuget  
Use Register-PSRepository to add this repository before installing this module  
Details for the repository.  
* Name                      : WellspanNuget  
* SourceLocation            : http://tsmgr4.wellspan.org:8080/nuget  
* PublishLocation           : http://tsmgr4.wellspan.org:8080/nuget  
* InstallationPolicy        : Trusted  

```powershell
Register-PSRepository  -name "WellspanNuget" -SourceLocation "http://tsmgr4.wellspan.org:8080/nuget" -PublishLocation "http://tsmgr4.wellspan.org:8080/nuget" -InstallationPolicy 'Trusted'

```

## Usage

List of functions in the Wellspan.SCOM module

```powershell
Clear-SCOMAgentHealthService -server serverName
Connect-SCOMDev
Connect-SCOMWsDev
Connect-SCOMProd
Connect-SCOMWsProd
Export-SCOMConfigReport -msServer mgtServerName
Get-NetFramework -server serverName
Get-RemoteRegistry -ComputerName $ServerName -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -RegistryValue "ProductName" [-Credential $Credential]  
Get-RemoteRegistryFast -ComputerName $ServerName -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" [-RegistryValue "ProductName"] (For different credentials run powershell as another user.  runas /user:<domain\user> "powershell.exe")  
Get-RemoteRegistryPathValues -ComputerName $ComputerName -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
Get-SCOMAgentWorkflow agentName
Get-SCOMLinuxAgentVersions
Get-SCOMLinuxComputers
Get-SCOMMMHistory [-Computer]  (Single computer or comma separated list)
Get-SCOMNodes
Get-SCOMNotifications
Get-SCOMWindowsAgentVersions
Get-SCOMWindowsComputers
Get-SQLTable -sqlServer SQLSERVER01 -sqlDatabase DATABASE -query "Select * from table" -credential (get-credential)
Get-SQLVersions SqlServers  (1 or a list of servers: sql01,sql02,sql03)
Remove-SCOMAgents -AgentComputerName agentName -MSServer mgtServer
Reset-SCOMMonitor [-Class (Get-SCOMClass -Name 'Microsoft.Windows.Computer') ,
                    -Instance (Get-SCOMClassInstance -DisplayName 'SERVER1.contoso.com') ,
                    -Monitor (Get-SCOMMonitor -displayname "Many Corrupt or Unreadable Windows Events") ]
                     -Force
Show-SCOMEffectiveMonitoring -server serverName
```

Each cmdlet has it's own help
The GetRegistry* cmdlets allow entries from the pipeline.  The values are a list of computers.  The debug option will display additional information.

```posh
"tsmgr1","tsmgr2","tsmgr3","tsmgr4"| Get-RemoteRegistryFast  -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"  
"tsmgr1","tsmgr2","tsmgr3","tsmgr4"| Get-RemoteRegistryFast  -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -RegistryValue ProductName
"tsmgr1","tsmgr2","tsmgr3","tsmgr4"| Get-RemoteRegistryPathValues  -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 
"tsmgr1","tsmgr2","tsmgr3","tsmgr4"| Get-RemoteRegistry  -RegistryPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -RegistryValue ProductName

```




## Requirements

```posh
Install-Script -Name Install-RequiredModule
```

## Building your module

1. run `Install-RequiredModule`

2. add `.ps1` script files to the `Source` folder

3. run `Build-Module .\Source`

4. compiled module appears in the `Output` folder

## Versioning

ModuleBuilder will automatically apply the next semver version
if you have installed [gitversion](https://gitversion.readthedocs.io/en/latest/).

To manually create a new version run `Build-Module .\Source -SemVer 0.0.2`

## Additional Information

[https://github.com/PoshCode/ModuleBuilder](https://github.com/PoshCode/ModuleBuilder)

## Support

* [File a bug or feature request](https://rhbldsrc.wellspan.org/automation-team/scom-module/-/issues)

## Roadmap

* No expansion planned at this time  
