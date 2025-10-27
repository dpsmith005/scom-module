function Export-SCOMConfigReport {
    <#
  .Synopsis
    Gather information about SCOM setup and configuration.
   .Description
    Gather detailed information about the SCOM environment.  This detailed data may be used for migration to a new SCOM environment.  
    The data is output to a html file.
   .Parameter msServer
    Management server name to begin the data collection.
   .Example
    Export-SCOMConfigReport -msServer scomms01
    Provide a SCOM management server name with the parameter name
   .Example
    Export-SCOMConfigReport scomms01
    Provide a SCOM management server name without the parameter name
   .Notes
    NAME:     Export-SCOMConfigReport
    AUTHOR:   David Smith
    LASTEDIT: 18 June 2025
    KEYWORDS:
  #Requires -Version 5.0
#>
    param([Parameter(Mandatory = $true)][string[]]$msServer)
    
    # Connect to the specified SCOM server and retrieve the management group name
    try {
        New-SCOMManagementGroupConnection -ComputerName $msServer
    }
    catch {
        Write-Error "Failed to connect to SCOM server $msServer"
        exit 1
    }
    $mgtGroupName = (Get-SCOMManagementGroup).Name

    # Output HTML Files
    $outFile = ".\$msServer-SCOMConfigReport_" + (get-date -format "yyyyMMdd_hhmmss") + ".html"
    $outFile2 = ".\$msServer-SCOMAgentReport_" + (get-date -format "yyyyMMdd_hhmmss") + ".html"
    $outFile3 = ".\$msServer-SCOMRunAsReport_" + (get-date -format "yyyyMMdd_hhmmss") + ".html"
    $outFile4 = ".\$msServer-SCOMManagementPacksReport_" + (get-date -format "yyyyMMdd_hhmmss") + ".html"

    # Start the HTML output
    $Header = @"
<style>
BODY{background-color:#CCCCCC;font-family:Calibri,sans-serif; font-size: small;}
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; width: auto} 
TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#293956;color:white;padding: 5px; font-weight: bold;text-align:left;}
TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#F0F0F0; padding: 2px;}
.tableList {border: 0px solid black; width: 400px}
.col1 {border: 0px solid black;width: 20px; background-color: #CCCCCC}
.col2 {width: 200px; background-color: #FFFFFF"}
.col3 {width: 120px; background-color: #FFFFFF"}
</style>
"@    
    $head = (ConvertTo-Html -title "SCOM Configuration Report for $mgtGroupName" -head $Header)[0..4]
    $end = (ConvertTo-Html -title "SCOM Configuration Report" )[-1]
    $htmlOut = $head
    $htmlOut += "`r`n<H1>SCOM Configuration Report for $mgtGroupName - $( Get-Date -UFormat "%A %B %d, %Y %T")</H1>`r`n"
    $htmlOut2 = $head
    $htmlOut2 += "`r`n<H1>SCOM Agent Report for $mgtGroupName - $( Get-Date -UFormat "%A %B %d, %Y %T")</H1>`r`n"
    $htmlOut3 = $head
    $htmlOut3 += "`r`n<H1>SCOM RunAs Report for $mgtGroupName - $( Get-Date -UFormat "%A %B %d, %Y %T")</H1>`r`n"
    $htmlOut4 = $head
    $htmlOut4 += "`r`n<H1>SCOM Management Packs Report for $mgtGroupName - $( Get-Date -UFormat "%A %B %d, %Y %T")</H1>`r`n"

    # Add Management Group information to the report
    $htmlOut += Get-SCOMManagementGroup | Convertto-html -Fragment -PreContent "`r`n<H2>SCOM Management Group Information</H2>`r`n" -Property Name, IsConnected, Version, SkuForLicense, SkuForProduct, TimeOfExpiration, CurrentCountryCode
    Write-Host Geting SCOM environment details ...

    # Add management server and gateway information
    $mgtServers = Get-SCOMManagementServer | Sort-Object DisplayName
    $htmlOut += $mgtServers | Sort-Object DisplayName | Convertto-html -Fragment -PreContent "`r`n<H2>Management Servers and Gateways</H2>`r`n" -Property DisplayName, IsRootManagementServer, IsGateway, AemEnabled, AutoApproveManuallyInstalledAgents, RejectManuallyInstalledAgents, MissingHeartbeatThreshold, HealthState, IPAddress, Version, CommunicationPort 

    # Add SCOM database information
    Write-Host Gathering Database information ...
    $databaseinfo = invoke-command -scriptblock { Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\" } -ComputerName $msServer | Select-Object DatabaseName, DatabaseServerName, DataWarehouseDBName, DataWarehouseDBServerName, CurrentVersion
    $htmlOut += "`r`n<H2>SCOM Database Information</H2>`r`n"
    $htmlOut += '<table class="tableList">'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>DataWarehouse DB Server Name</b></td><td class="col3">' + $databaseinfo.DataWarehouseDBServerName + '</td></tr>'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>DataWarehouse DB Name</b></td><td class="col3">' + $databaseinfo.DataWarehouseDBName + '</td></tr>'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>Database Server Name</b></td><td class="col3">' + $databaseinfo.DatabaseServerName + '</td></tr>'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>Database Name </b></td><td class="col3">' + $databaseinfo.DatabaseName + '</td></tr>'
    $htmlOut += '</table>'
    $scomSQL = [PSCustomObject]@{
        'DatawarehouseServer' = $databaseinfo.DataWarehouseDBServerName
        'DatawarehouseDB'     = $databaseinfo.DataWarehouseDBName
        'DatabaseServer'      = $databaseinfo.DatabaseServerName
        'DatabaseDB'          = $databaseinfo.DatabaseName
    }

    # Get SCOM SQL server details
    if ($databaseinfo.DatabaseServerName -eq $databaseinfo.DataWarehouseDBServerName) {
        $sqlServers = @($databaseinfo.DatabaseServerName)
    }
    else {
        $sqlServers = @($databaseinfo.DatabaseServerName, $databaseinfo.DataWarehouseDBServerName)
    }
    $result = Get-SqlVersions $sqlServers | Select-Object MachineName, Release_Name, Type, DisplayName, Version, Edition, Started, StartMode, State, Status, ServiceAccount
    #$result | Where-Object { $sqlServers -contains $_.machinename }
    if ([string]::IsNullOrEmpty($result)) {
        $htmlOut += "`r`n<H2>SCOM SQL Server Information</H2>`r`n<p>Unable to retrieve SQL Versions</p>"
    }
    else {
        $htmlOut += $result | ConvertTo-Html -fragment -PreContent "`r`n<H2>SCOM SQL Server Information</H2>`r`n"
    }

    # Create and array with management servers and sql servers
    $MgtAndSqlServers = @()
    foreach ($servername in $mgtServers.Displayname) { $MgtAndSqlServers += $servername }
    foreach ($servername in $sqlServers) { $MgtAndSqlServers += $servername }

    # Test Remoting connection to $mgtServers
    $connectionState = @{}
    foreach ($servername in $MgtAndSqlServers) { 
        try {
            $test = invoke-command -ScriptBlock { get-host } -ComputerName $servername -ErrorAction Stop
            $connectionState[$serverName] = $true
        }
        catch {
            Write-Host WinRm not connecting to $servername
            $connectionState[$serverName] = $false
        }
    }
	
    # Get SQL Version from SQL query
    foreach ($sqlServer in $sqlServers) {
        # Get the SQL version of the specified system
        $sqlVer = (Get-SqlTable $sqlServer master "select @@Version").Column1
        $htmlOut += "<h3>&nbsp;&nbsp;&nbsp;&nbsp;$sqlServer</h3>`r`n<pre>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$sqlver</pre>`r`n"
    }
    # Get the SQL OLE and ODBC Version
    foreach ($s in $sqlServers ) {
        $dbConnectors = Invoke-Command -computer $sqlServer { Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft", "HKLM:\SOFTWARE\Wow6432Node\Microsoft" | `
                Where-Object { $_.Name -like "*MSOLEDBSQL*" -or $_.Name -like "*MSODBCSQL*" } | `
                ForEach-Object { Get-ItemProperty $_.PSPath } }
        if ([string]::IsNullOrEmpty($dbConnectors)) { 
            $htmlOut += "<h4>SQL DB Connectors</h4>`r`n<p>Unable to retrieve DB connector information</p>`r`n"
        }
        else {
            $htmlOut += $dbConnectors | Select-Object PSComputerName, InstalledVersion, PSChildName, PSPath | convertto-html -Fragment -PreContent "SQL DB Connectors"    
        }
    }

    # Display Servers with the Console and WebConsole
    Write-Host Gathering console anfd web console info ...
    $arr = @()
    foreach ($s in ($mgtServers | Where-Object { $_.IsGateway -eq $false })) {
        $console = invoke-command -scriptblock { Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Console\" } -ComputerName $s.DisplayName
        if ( [string]::IsNullOrEmpty($console.'RTM_UR Version') ) {
            $isConsole = $false
            $verConsole = "No Console"
        }
        else {
            $isConsole = $true
            $verConsole = $console.'RTM_UR Version'
        }
        $webConsole = invoke-command -scriptblock { Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\WebConsole\" -ErrorAction 0 } -ComputerName $s.DisplayName
        if ( [string]::IsNullOrEmpty($webConsole.'RTM_UR Version') ) {
            $isWebConsole = $false
            $verWebConsole = "No Console"
        }
        else {
            $isWebConsole = $true
            $verWebConsole = $console.'RTM_UR Version'
        }
        $result = [PSCustomObject]@{
            'Management Server'   = $s.DisplayName
            'isConsole'           = $isConsole
            'Console Version'     = $verConsole
            'isWebConsole'        = $isWebConsole
            'Web Console Version' = $verWebConsole
        }
        $arr += $result
    }
    $out = ($arr | ConvertTo-Html -fragment -PreContent "`r`n<H2>Management Server Console / Web Console Information</H2>`r`n")
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut += $out

    # Display the management server OS and hardware specifics   
    Write-Host Gather management server OS and hardware specs ...
    $arr = @()
    foreach ($ms in $MgtAndSqlServers) {
        Remove-Variable os  -ErrorAction 0
        $os = Get-OSversion $ms -ErrorAction 0
        if ([string]::IsNullOrEmpty($os.computer) ) {
            # Use the scom data for os information because there is an issue connecting to the Server
            Write-Host $ms connection failed
            $connectionState[$ms] = $false
            $cp = Get-SCOMClass -Name Microsoft.Windows.Server.Computer | get-scomclassinstance | Where-Object { $_.DisplayName -match $ms }
            $win = Get-SCOMClass -Name Microsoft.Windows.OperatingSystem | get-scomclassinstance | Where-Object { $_.Path -match $ms }
            $result = [PSCustomObject]@{
                'Computer'                  = $ms
                'Caption'                   = $win.DisplayName  #[Microsoft.Windows.OperatingSystem].OSVersionDisplayName
                'Version'                   = $win.'[Microsoft.Windows.OperatingSystem].OSVersion'.value
                'LastBootUpTime'            = "unable to retrieve"
                'TotalVirtualMemorySizeGB'  = "unknown"
                'TotalPhysicalMemoryGB'     = [int]($win.'[Microsoft.Windows.OperatingSystem].PhysicalMemory'.value / 1MB)   #[Microsoft.Windows.OperatingSystem].PhysicalMemory
                'NumberOfProcessors'        = $cp.'[Microsoft.Windows.Computer].PhysicalProcessors'.value     #[Microsoft.Windows.Computer].PhysicalProcessors
                'NumberOfLogicalProcessors' = $cp.'[Microsoft.Windows.Computer].LogicalProcessors'.value   #[Microsoft.Windows.OperatingSystem].LogicalProcessors
            }
        }
        else {
            $result = $os
        }
        $arr += $result
    }
    $out = ($arr | ConvertTo-Html -fragment -PreContent "`r`n<H2>Management Server, SQL Server & Gateway Info for OS and hardware</H2>`r`n")
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut += $out

    #Management Server Agent count
    Write-Host Gathering Agent counts ...
    $mgtAgentCount = Get-SCOMManagementServer | Sort-Object DisplayName | % { $x = (Get-SCOMAgent -ManagementServer $_).DisplayName.count; [pscustomobject]@{MgtServer = $_.DisplayName; ServerCount = $x } }
    $out = ($mgtAgentCount | ConvertTo-Html -fragment -PreContent "`r`n<H2>Management Servers & Gateways Agent Count</H2>`r`n")
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut += $out
    $htmlOut += '<a href="https://learn.microsoft.com/en-us/powershell/module/operationsmanager/set-scomparentmanagementserver?view=systemcenter-ps-2025">Set-SCOMParentManagementServer</a>' + "`&nbsp;&nbsp;&nbsp;&nbsp;`r`n"
    $htmlOut += '<a href="https://kevinholman.com/2018/08/06/assigning-gateways-and-agents-to-management-servers-using-powershell/">Assign Gateways and Agents to Management Servers</a><br>' + "`r`n"

    # Check the asnyc Process Limit values
    Write-Host Gathering registry info ...
    $arr = @()
    foreach ($serverName in ($mgtServers.DisplayName)) {
        if ($connectionState[$serverName]) {
            try {
                $key = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Modules\Global\Command Executer\"
                $asyncProcessLimit = (invoke-command -scriptblock { param($key); Get-ItemProperty $key -ErrorAction Stop } -ComputerName $serverName -ArgumentList $key -ErrorAction 0).AsyncProcessLimit    
                if ([string]::IsNullOrEmpty($asyncProcessLimit)) { $asyncProcessLimit = 0 }
                $arr += [PSCustomObject]@{ServerName = $serverName; asyncProcessLimit = $asyncProcessLimit }
            }
            catch {
                switch ($_.Exception.Message) {
                    'Connecting to remote server' { Write-Error Unable to connect to server $serverName ; break }
                    'Cannot find path' { Write-Error Cannot find key $key ; break }
                    #'' { ; break}
                }
            }
        }
        else {
            Write-Host Connection State Failed for $serverName.  Not collecting asyncProcessLimit
            $arr += [PSCustomObject]@{ServerName = $serverName; asyncProcessLimit = "Failed to collect" }
        }
    }
    $out = ($arr | ConvertTo-Html -fragment -PreContent "`r`n<H2>Management Servers AsyncProcessLimit Registry Value</H2>`r`n")
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut += $out
    $htmlOut += "<p><b>HKEY_LOCAL_MACHINE\Software\Microsoft\Microsoft Operations Manager\3.0\Modules\Global\Command Executer\AsyncProcessLimit  Valid values 5-100 (Set to 80)</b></p>`r`n"
    #$htmlOut += '<a href=""'> </a><br> + "`r`n"

    # Gather registry values used to tune SCOM - https://kevinholman.com/2017/03/08/recommended-registry-tweaks-for-scom-2016-management-servers/
    $arr = @()
    foreach ($serverName in $MgtAndSqlServers) {
        if ($connectionState[$serverName]) {
            try {
                $key = "HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters" # "State Queue Items" 
                $StateQueueItems = (invoke-command -scriptblock { param($key); Get-ItemProperty -Path $key -ErrorAction 0 } -ComputerName $serverName -ArgumentList $key).'State Queue Items'
                $key = "HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters" # "Persistence Checkpoint Depth Maximum"
                $PersistenceCheckpointDepthMaximum = (invoke-command -scriptblock { param($key); Get-ItemProperty -Path $key -ErrorAction 0 } -ComputerName $serverName -ArgumentList $key).'Persistence Checkpoint Depth Maximum'
                $key = "HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL" # "DALInitiateClearPool"
                $DALInitiateClearPool = (invoke-command -scriptblock { param($key); Get-ItemProperty -Path $key -ErrorAction 0 } -ComputerName $serverName -ArgumentList $key).DALInitiateClearPool
                $key = "HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL" # "DALInitiateClearPoolSeconds"
                $DALInitiateClearPoolSeconds = (invoke-command -scriptblock { param($key); Get-ItemProperty -Path $key -ErrorAction 0 } -ComputerName $serverName -ArgumentList $key).DALInitiateClearPoolSeconds
                $key = "HKLM:\SOFTWARE\Microsoft\System Center\2010\Common" # "GroupCalcPollingIntervalMilliseconds"
                $GroupCalcPollingIntervalMilliseconds = (invoke-command -scriptblock { param($key); Get-ItemProperty -Path $key -ErrorAction 0 } -ComputerName $serverName -ArgumentList $key).GroupCalcPollingIntervalMilliseconds
                $key = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse" # "Command Timeout Seconds"
                $CommandTimeoutSeconds = (invoke-command -scriptblock { param($key); Get-ItemProperty -Path $key -ErrorAction 0 } -ComputerName $serverName -ArgumentList $key).'Command Timeout Seconds'
                $key = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse" # "Deployment Command Timeout Seconds"
                $DeploymentCommandTimeoutSeconds = (invoke-command -scriptblock { param($key); Get-ItemProperty -Path $key -ErrorAction 0 } -ComputerName $serverName -ArgumentList $key).'Deployment Command Timeout Seconds'
                #$key = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"
                #$out = (invoke-command -scriptblock { param($key); Get-ItemProperty $key -ErrorAction 0 } -ComputerName $serverName -ArgumentList $key).DefaultSDKServiceMachine
                $arr += [PSCustomObject]@{
                    ServerName                           = $serverName; 
                    StateQueueItems                      = $StateQueueItems; 
                    PersistenceCheckpointDepthMaximum    = $PersistenceCheckpointDepthMaximum; 
                    DALInitiateClearPool                 = $DALInitiateClearPool;
                    DALInitiateClearPoolSeconds          = $DALInitiateClearPoolSeconds;
                    GroupCalcPollingIntervalMilliseconds = $GroupCalcPollingIntervalMilliseconds;
                    CommandTimeoutSeconds                = $CommandTimeoutSeconds;
                    DeploymentCommandTimeoutSeconds      = $DeploymentCommandTimeoutSeconds;
                }
            }
            catch {
                switch ($_.Exception.Message) {
                    'Connecting to remote server' { Write-Error Unable to connect to server $serverName ; break }
                    'Cannot find path' { Write-Error Cannot find key $key ; break }
                    #'' { ; break}
                }
            }
        }
        else {
            Write-Host Connection State Failed for $serverName.  Not collecting registry values
            $arr += [PSCustomObject]@{
                ServerName                           = $serverName; 
                StateQueueItems                      = "Failed to collect"; 
                PersistenceCheckpointDepthMaximum    = "Failed to collect"; 
                DALInitiateClearPool                 = "Failed to collect";
                DALInitiateClearPoolSeconds          = "Failed to collect";
                GroupCalcPollingIntervalMilliseconds = "Failed to collect";
                CommandTimeoutSeconds                = "Failed to collect";
                DeploymentCommandTimeoutSeconds      = "Failed to collect";
            }
        }

    }
    $htmlOut += $arr | ConvertTo-Html -fragment -PreContent "`r`n<H2>Management Servers Registry Values</H2>`r`n"
    $htmlOut += '<a href= "https://kevinholman.com/2017/03/08/recommended-registry-tweaks-for-scom-2016-management-servers/">Registry Tweaks</a><br>' + "`r`n"

    # Data Aggregation in DW (scomsql04 OperationsManagerDW)
    Write-Host Gathering DW aggregation ...
    $query = @"
SELECT * 
FROM StandardDatasetAggregation sda 
INNER JOIN dataset ds on ds.datasetid = sda.datasetid 
ORDER BY DataSetDefaultName
"@
    $data = Get-SqlTable -sqlServer $scomSQL.DatawarehouseServer -sqlDatabase $scomSQL.DatawarehouseDB -query $query
    $result = $data | Select-Object DatasetDefaultName, AggregationTypeId, @{N = "AggregationTypeName"; E = { switch ($_.AggregationTypeId) { 0 { "Raw"; Break }; 20 { "Hourly"; Break } 30 { "Daily"; Break } } } }, MaxDataAgeDays
    $out = ($result | ConvertTo-Html -fragment -PreContent "`r`n<H2>Aggregation for Datawarehouse</H2>`r`n")
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut += $out
    $htmlOut += '<a href= "https://kevinholman.com/2010/01/05/understanding-and-modifying-data-warehouse-retention-and-grooming/">Setting Datawarehouse Retention</a><br>' + "`r`n"

    # Data Grooming in DB (scomsql03 OperationsManager)
    Write-Host Gathering DB data grooming ...
    $query = "select * from PartitionAndGroomingSettings"
    $data = Get-SqlTable -sqlServer $scomSQL.DatabaseServer -sqlDatabase $scomSQL.DatabaseDB -query $query
    $result = $data | Select-Object IsPartitioned, DaysToKeep, GroomingRunTime, DataGroomedMaxTime, IsInternal, InsertViewName , GroomingSproc
    $out = $result | ConvertTo-Html -fragment -PreContent "`r`n<H2>Data Grooming for Database</H2>`r`n"
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut += $out
    $htmlOut += '<a href="https://kevinholman.com/2008/02/12/grooming-process-in-the-scom-database/">Grooming Process in the SCOM Database</a><br>' + "`r`n"

    # State Change
    Write-Host Gather state changes ...
    $query = @"
declare @statedaystokeep INT 
SELECT @statedaystokeep = DaysToKeep from PartitionAndGroomingSettings WHERE ObjectName = 'StateChangeEvent' 
SELECT COUNT(*) as 'Total StateChanges', 
count(CASE WHEN sce.TimeGenerated > dateadd(dd,-@statedaystokeep,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as 'within grooming retention', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-@statedaystokeep,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> grooming retention', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-30,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> 30 days', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-90,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> 90 days', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-365,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> 365 days' 
from StateChangeEvent sce
"@
    $data = Get-SqlTable -sqlServer $scomSQL.DatabaseServer -sqlDatabase $scomSQL.DatabaseDB -query $query
    $htmlOut += "`r`n<H2>State Changes</H2>`r`n"
    $htmlOut += '<table class="tableList">'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>Total StateChanges</b></td><td class="col3">' + $data.'Total StateChanges' + '</td></tr>'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>within grooming retention </b></td><td class="col3">' + $data.'within grooming retention' + '</td></tr>'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>grooming retention </b></td><td class="col3">' + $data.'> grooming retention' + '</td></tr>'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>&gt; 30 days</b></td><td class="col3">' + $data.'> 30 days' + '</td></tr>'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>&gt; 90 days </b></td><td class="col3">' + $data.'> 90 days' + '</td></tr>'
    $htmlOut += '<tr><td class="col1"></td><td class="col2"><b>&gt; 365 days </b></td><td class="col3">' + $data.'> 365 days' + '</td></tr>'
    $htmlOut += '</table>'
    #$htmlOut += $data | Select-Object Total*, with*, '> *' | ConvertTo-Html -fragment -PreContent "`r`n<H2>State Changes</H2>`r`n" -as List

    # Database Stats
    Write-Host Gather database and DW stats ...
    $query = @"
select a.FILEID, 
[FILE_SIZE_MB]=convert(decimal(12,2),round(a.size/128.000,2)), 
[SPACE_USED_MB]=convert(decimal(12,2),round(fileproperty(a.name,'SpaceUsed')/128.000,2)), 
[FREE_SPACE_MB]=convert(decimal(12,2),round((a.size-fileproperty(a.name,'SpaceUsed'))/128.000,2)) , a.Growth, 
NAME=left(a.NAME,15), 
FILENAME=a.FILENAME
from dbo.sysfiles a
"@
    $data = Get-SqlTable -sqlServer $scomSQL.DatabaseServer -sqlDatabase $scomSQL.DatabaseDB -query $query
    $result = $data | Select-Object NAME, FILE_SIZE_MB, SPACE_USED_MB, FREE_SPACE_MB, @{N = "FreePct"; E = { ($_.FREE_SPACE_MB / $_.FILE_SIZE_MB * 100).ToString("#.##") } }, FILENAME, GROWTH
    $out = $result | ConvertTo-Html -fragment -PreContent "`r`n<H2>Database Stats</H2>`r`n" 
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut += $out

    # Datawarehouse Stats (Uses the same query as the database)
    $data = Get-SqlTable -sqlServer $scomSQL.DatawarehouseServer -sqlDatabase $scomSQL.DatawarehouseDB -query $query
    $result = $data | Select-Object NAME, FILE_SIZE_MB, SPACE_USED_MB, FREE_SPACE_MB, @{N = "FreePct"; E = { ($_.FREE_SPACE_MB / $_.FILE_SIZE_MB * 100).ToString("#.##") } }, FILENAME, GROWTH
    $out = $result | ConvertTo-Html -fragment -PreContent "`r`n<H2>Datawarehouse Stats</H2>`r`n" 
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut += $out

    # ResourcePools
    Write-Host Gather Resource pools ...
    $data = Get-SCOMResourcePool | Select-Object Name, DisplayName, @{N = "Members"; E = { $_.Members.DisplayName -join "," } }
    $htmlOut += $data | ConvertTo-Html -fragment -PreContent "`r`n<H2>Resource Pools </H2>`r`n" 


    # Not Monitored Agents (scomsql03 OperationsManager)
    Write-Host Gather agents list that are not monitored ...
    $query = @"
select bme.DisplayName, IsAvailable, ReasonCode from Availability 
join BaseManagedEntity as bme on bme.BaseManagedEntityId = Availability.BaseManagedEntityId
where isavailable = 0 AND bme.IsDeleted = '0' 
"@
    $data = Get-SqlTable -sqlServer $scomSQL.DatabaseServer -sqlDatabase $scomSQL.DatabaseDB -query $query
    $result = $data | Select-Object DisplayName, IsAvailable, ReasonCode
    $out = $result | ConvertTo-Html -fragment -PreContent "`r`n<H2>Not Monitored Agents </H2>`r`n" 
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut += $out

    # Agents Pending State  (scomsql03 OperationsManager)
    Write-Host Gather agents pending management ...
    $query = @"
SELECT [AgentName]
      ,[ManagementServerName]
      ,[PendingActionType]
	  ,case 
		when [PendingActionType]=1 Then 'PushInstall'
		when [PendingActionType]=19 Then 'RepairFailed'
		else CONVERT(varchar(20), [PendingActionType])
	  end as [Pending Action]
      --,[PendingActionData]
      ,[LastModified]
  FROM [OperationsManager].[dbo].[AgentPendingAction]
"@
    $data = Get-SqlTable -sqlServer $scomSQL.DatabaseServer -sqlDatabase $scomSQL.DatabaseDB -query $query
    $result = $data | Select-Object AgentName, ManagementServerName, 'Pending Action', LastModified
    $htmlOut += $result | ConvertTo-Html -fragment -PreContent "`r`n<H2>Agents Pending State </H2>`r`n" 

    # Health Service distribution RunAs (OperationsManager)
    Write-Host Gather Health service distribution ...
    $QUERY = @"
select 
  cms.Name as 'Runas Account Name',
  cms.Domain as 'Runas Domain Name',
  cms.UserName as 'Runas UserName',
  hsvc.DisplayName as 'Health Service'
  from CredentialHealthService CH
  left outer join CredentialManagerSecureStorage cms on CH.SecureStorageElementId = cms.SecureStorageElementId
  inner join MT_HealthService hsvc on hsvc.BaseManagedEntityId = CH.healthserviceid
"@
    $data = Get-SqlTable -sqlServer $scomSQL.DatabaseServer -sqlDatabase $scomSQL.DatabaseDB -query $query
    $htmlOut += $data | Select-Object 'Runas Account Name', 'Runas Domain Name', 'Runas UserName', 'Health Service' | Sort-Object 'Runas Account Name', 'Health Service' | ConvertTo-Html -fragment -PreContent "`r`n<H2>Health Service RunAs distribution </H2>`r`n" 

    # Get Alert counts by resolution state
    Write-Host Gather Alert details ...
    $hash = @{}; Get-SCOMAlertResolutionState | ForEach-Object { $hash[$_.ResolutionState] = $_.Name }
    $alerts = Get-SCOMAlert -ResolutionState (0..254) | Select-Object *, @{N = "ResolutionName"; E = { $hash[$_.ResolutionState] } } 
    $result = $alerts | Select-Object severity, priority, resolutionstate, resolutionname, timeRaised, Name | Group-Object ResolutionName, Severity, Priority -NoElement | Select-Object Count, @{N = "Resolution"; E = { $_.Name.split(",")[0] } }, @{N = "Severity"; E = { $_.Name.Split(",")[1] } }, @{N = "priority"; E = { $_.Name.Split(",")[2] } }
    $out = $result | ConvertTo-Html -fragment -PreContent "`r`n<H3>Alert Counts</H3>`r`n" 
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    # Alert has Ticket counts
    $hasTicket = $alerts | Select-Object owner, MonitoringObjectDisplayName, MonitoringObjectName, MonitoringObjectPath, MonitoringObjectFullName, TicketID, @{N = "hasTicket"; E = { if ([string]::IsNullOrEmpty($_.TicketID)) { $false } else { $true } } } | Group-Object hasTicket -NoElement | Select-Object Count, @{N = "hasTicket"; E = { $_.Name } }
    $hasTicket = $hasTicket | ConvertTo-Html -fragment -PreContent "`r`n<H3>Alerts with Ticket Counts</H3>`r`n" 
    $hasTicket = $hasTicket.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $hasTicket = $hasTicket.replace("<table>", '<table style="width:auto">')
    # Alert has ticket, count by owner
    $hasTicketOwner = $alerts | Select-Object owner, MonitoringObjectDisplayName, MonitoringObjectName, MonitoringObjectPath, MonitoringObjectFullName, TicketID, @{N = "hasTicket"; E = { if ([string]::IsNullOrEmpty($_.TicketID)) { $false } else { $true } } } | Where-Object { $_.hasTicket } | Group-Object owner -NoElement | Select-Object Count, @{N = "Owner"; E = { $_.Name } }
    $hasTicketOwner = $hasTicketOwner | ConvertTo-Html -fragment -PreContent "`r`n<H3>Alerts with Ticket by Owner Counts</H3>`r`n" 
    $hasTicketOwner = $hasTicketOwner.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $hasTicketOwner = $hasTicketOwner.replace("<table>", '<table style="width:auto">')
    # Create nested tables to be side by side    
    $nestedTables = @"
<h2>Alerts</h2>
<table style="border-width: 0px; background-color:#CCCCCC">
  <tr>
	<td style="border-width: 0px; vertical-align: top; background-color:#CCCCCC">
TABLE01
    </td>
	<td style="width: 10px; border-width: 0px; background-color:#CCCCCC; vertical-align: top"></td>
	<td style="border-width: 0px; vertical-align: top; background-color:#CCCCCC">
TABLE02
	</td>
	<td style="width: 10px; border-width: 0px; background-color:#CCCCCC; vertical-align: top"></td>
	<td style="border-width: 0px; vertical-align: top; background-color:#CCCCCC">
TABLE03
	</td>
  </tr>
</table>
"@
    $nestedTables = $nestedTables.Replace("TABLE01", $out)
    $nestedTables = $nestedTables.Replace("TABLE02", $hasTicket)
    $nestedTables = $nestedTables.Replace("TABLE03", $hasTicketOwner)
    $htmlout += $nestedTables 

    # OS counts for windows and linux
    Write-Host Gather agent OS counts ...
    $linuxOSCounts = Get-scomclass -name Microsoft.Unix.Computer | Get-SCOMClassInstance | Select-Object name, @{N = "GuestOS"; E = { $_.'[LW.Microsoft.SCX.Agent.Instance].GuestOS'.value } } | Group-Object GuestOS -NoElement  | Select-Object Count, @{N = "GuestOS"; E = { $_.Name } }
    $linuxOSCounts = $linuxOSCounts | ConvertTo-Html -fragment -PreContent "`r`n<H3>Linux OS  Counts</H3>`r`n" 
    $linuxOSCounts = $linuxOSCounts.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $linuxOSCounts = $linuxOSCounts.replace("<table>", '<table style="width:auto">')
    $winOSCounts = Get-scomclass -name Microsoft.Windows.Server.OperatingSystem | Get-SCOMClassInstance | Select-Object path, displayname | Group-Object displayname -NoElement | Select-Object Count, @{N = "DisplayName"; E = { $_.Name } }
    $winOSCounts = $winOSCounts | ConvertTo-Html -fragment -PreContent "`r`n<H3>Windows OS  Counts</H3>`r`n" 
    $winOSCounts = $winOSCounts.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $winOSCounts = $winOSCounts.replace("<table>", '<table style="width:auto">')
    $nodesName = (get-scomclass -name  System.NetworkManagement.Node | Get-SCOMClassInstance).DisplayName -Join ", "
    $nodeCount = (Get-scomclass -name  System.NetworkManagement.Node | Get-SCOMClassInstance).count
    # Create nested tables to be side by side   
    $nestedTables = @"
<h2>Operating Systems</h2>
<table style="border-width: 0px; background-color:#CCCCCC; vertical-align: top;">
  <tr>
	<td style="border-width: 0px; vertical-align: top; background-color:#CCCCCC">
TABLE01
    </td>
	<td style="width: 10px; border-width: 0px; background-color:#CCCCCC;"></td>
	<td style="border-width: 0px; vertical-align: top; background-color:#CCCCCC">
TABLE02
	</td>
	<td style="width: 10px; border-width: 0px; background-color:#CCCCCC; vertical-align: top"></td>
	<td style="border-width: 0px; vertical-align: top; background-color:#CCCCCC">
        <h3>Nodes</h3>
        <table style='width:auto'>
            <tr><th>Node Count</th><th>Nodes</th></tr>
            <tr><td>$($nodeCount) </td><td style='width:400px'>$($nodesName) </td></tr>
        </table>
	</td>    
  </tr>
</table>
"@
    $nestedTables = $nestedTables.Replace("TABLE01", $linuxOSCounts)
    $nestedTables = $nestedTables.Replace("TABLE02", $winOSCounts)
    $htmlout += $nestedTables 


    <# To Be Added
-Management Server Agent count
         Get-SCOMManagementServer |Sort-Object DisplayName | %{$x=(Get-SCOMAgent -ManagementServer $_).DisplayName.count; [pscustomobject]@{MgtServer = $_.DisplayName; ServerCount = $x} }
         '<a href="https://learn.microsoft.com/en-us/powershell/module/operationsmanager/set-scomparentmanagementserver?view=systemcenter-ps-2025">Set-SCOMParentManagementServer</a><br>' + "`r`n"

-Get Windows, linux, and nodes - counts by Agent version, OS, Alert severity
    -Agent
    get-scomclass -name  System.NetworkManagement.Node|Get-SCOMClassInstance|Select DisplayName, InMaintenanceMode, HealthState, @{N="AccessMode";E={$_.'[System.NetworkManagement.Node].AccessMode'}}
    $nodesName =  (get-scomclass -name  System.NetworkManagement.Node|Get-SCOMClassInstance).DisplayName -Join ", "
    $nodeCount = (Get-scomclass -name  System.NetworkManagement.Node|Get-SCOMClassInstance).count
    $linuxAgtCounts = Get-SCXAgent|select name, IPAddress, UnixComputerType, AgentVersion|Group-Object UnixComputerType,AgentVersion -NoElement
    $winAgtCounts = Get-SCOMAgent|select Name, Domain, IPAddress, PrimaryManagementServerName, Version, PatchList|Group-Object Version,PatchList -NoElement
    -OS
    $linuxOSCounts = Get-scomclass -name Microsoft.Unix.Computer |Get-SCOMClassInstance|select name, @{N="GuestOS";E={$_.'[LW.Microsoft.SCX.Agent.Instance].GuestOS'.value}} | Group-Object GuestOS -NoElement
    $winOSCounts = Get-scomclass -name Microsoft.Windows.Server.OperatingSystem | Get-SCOMClassInstance | select path, displayname|Group-Object displayname -NoElement
    -Alerts
    $alerts=Get-SCOMAlert -ResolutionState (0..254)
    # Has Ticket counts
      $hasTicket = $alerts|select owner, MonitoringObjectDisplayName, MonitoringObjectName, MonitoringObjectPath, MonitoringObjectFullName, TicketID, @{N="hasTicket";E={if ([string]::IsNullOrEmpty($_.TicketID)) {$false} else {$true}}} | Group-Object hasTicket -NoElement
    # Has ticket, count by owner
      $hasTicketOwner = $alerts|select owner, MonitoringObjectDisplayName, MonitoringObjectName, MonitoringObjectPath, MonitoringObjectFullName, TicketID, @{N="hasTicket";E={if ([string]::IsNullOrEmpty($_.TicketID)) {$false} else {$true}}} | ?{$_.hasTicket}|Group-Object owner -NoElement

Get all Node, Linux, and Windows Agent and OS info      

Notification Information - Get-SCONotifications

Get SQL server info
    $sqlServersGroup = get-scomgroup -DisplayName "MSSQL: Generic DB Engine Group" | Get-SCOMClassInstance | Select * #| % { $_.'[Microsoft.SQLServer.Core.DBEngine].MachineName'.value } | sort
    $values=@("MachineName","Account","Version","Edition","MasterDatabaseLocation","MasterDatabaseLogLocation","ErrorLogLocation","InstallPath","ToolsPath")

    $hashSqlVer = @{}
    $hashSqlVer['8'] = 'SQL Server 2000'
    $hashSqlVer['9'] = 'SQL Server 2005'
    $hashSqlVer['10.0'] = 'SQL Server 2008'
    $hashSqlVer['10.5']= 'SQL Server 2008 R2'
    $hashSqlVer['11'] = 'SQL Server 2012'
    $hashSqlVer['12'] = 'SQL Server 2014'
    $hashSqlVer['13'] = 'SQL Server 2016'
    $hashSqlVer['14'] = 'SQL Server 2017'
    $hashSqlVer['15'] = 'SQL Server 2019'
    $hashSqlVer['16']  ='SQL Server 2022'
    $hashSqlVer['17']  ='SQL Server 2026'
    
    $sqlServersClass =  get-scomclass -name "Microsoft.SQLServer.Windows.DBEngine" | get-scomclassinstance

    $SqlServerInfo = $sqlServersClass | Select DisplayName, `
    @{N="MachineName";E={$_.'[Microsoft.SQLServer.Core.DBEngine].MachineName'.value}}, `
    @{N="MasterDatabaseLogLocation";E={$_.'[Microsoft.SQLServer.Windows.DBEngine].MasterDatabaseLogLocation'.value}}, `
    @{N="ErrorLogLocation";E={$_.'[Microsoft.SQLServer.Windows.DBEngine].ErrorLogLocation'.value}}, `
    @{N="InstallPath";E={$_.'[Microsoft.SQLServer.Windows.DBEngine].InstallPath'.value}}, `
    @{N="ToolsPath";E={$_.'[Microsoft.SQLServer.Windows.DBEngine].ToolsPath'.value}}, `
    @{N="Account";E={$_.'[Microsoft.SQLServer.Windows.DBEngine].Account'.value}}, `
    @{N="Version";E={$_.'[Microsoft.SQLServer.Core.DBEngine].Version'.value}}, `
    @{N="Edition";E={$_.'[Microsoft.SQLServer.Core.DBEngine].Edition'.value}}, `
    @{N="AuthenticationMode";E={$_.'[Microsoft.SQLServer.Windows.DBEngine].AuthenticationMode'.value}}, `
    @{N="Type";E={$_.'[Microsoft.SQLServer.Core.DBEngine].Type'.value}}, `
    IsManaged, HealthState, StateLastModified, IsAvailable, AvailabilityLastModified, InMaintenanceMode, MaintenanceModeLastModified | select MachineName, DisplayName, Type, @{N="VersionName";E={$hashSqlVer[$_.version.split(".")[0]]}}, Edition, Version, Account, AuthenticationMode, IsManaged, HealthState, StateLastModified, IsAvailable, AvailabilityLastModified, InMaintenanceMode, MaintenanceModeLastModified, MasterDatabaseLogLocation, ErrorLogLocation, InstallPath

    # SQL server version name base on version number
    $SqlVersionName = switch -Regex ($versionNumber) {
        '^8' { 'SQL Server 2000'; Break}
        '^9' { 'SQL Server 2005'; Break }
        '^10.0' { 'SQL Server 2008'; Break }
        '^10.5' { 'SQL Server 2008 R2'; Break }
        '^11' { 'SQL Server 2012'; Break }
        '^12' { 'SQL Server 2014'; Break }
        '^13' { 'SQL Server 2016'; Break }    
        '^14' { 'SQL Server 2017'; Break } 
        '^15' { 'SQL Server 2019'; Break } 
        '^16' { 'SQL Server 2022'; Break } 
        '^17' { 'SQL Server 2026 ?'; Break } 
        default { "Unknown SQL Server Version" }
    }

    $sqlDBs = get-scomclass -name 'Microsoft.SQLServer.Windows.Database'|Get-SCOMClassInstance  #|select path, @{N="databaseName";E={$_.'[Microsoft.SQLServer.Core.Database].DatabaseName'.value}}|sort name,databasename
    $SqlDbInfo = $sqlDBs | select Path, Name, `
    @{N="MachineName";E={$_.'[Microsoft.SQLServer.Core.DBEngine].MachineName'.value}}, `
    @{N="DatabaseName";E={$_.'[Microsoft.SQLServer.Core.Database].DatabaseName'.value}}, `
    @{N="Collation";E={$_.'[Microsoft.SQLServer.Core.Database].Collation'.value}}, `
    @{N="RecoveryModel";E={$_.'[Microsoft.SQLServer.Core.Database].RecoveryModel'.value}}, `
    @{N="Updateability";E={$_.'[Microsoft.SQLServer.Core.Database].Updateability'.value}}, `
    @{N="DatabaseAutogrow";E={$_.'[Microsoft.SQLServer.Core.Database].DatabaseAutogrow'.value}}, `
    @{N="LogAutogrow";E={$_.'[Microsoft.SQLServer.Core.Database].LogAutogrow'.value}}, `
    @{N="UserAccess";E={$_.'[Microsoft.SQLServer.Core.Database].UserAccess'.value}}, `
    @{N="Owner";E={$_.'[Microsoft.SQLServer.Core.Database].Owner'.value}}, `
    IsManaged, HealthState, StateLastModified, IsAvailable, AvailabilityLastModified, InMaintenanceMode, MaintenanceModeLastModified 
#>

    ######################################################
    ##### Move the SCOM functions to the SCOM Module #####
    ######################################################

    #$htmlOut += $result | ConvertTo-Html -fragment -PreContent "`r`n<H2> </H2>`r`n" 



    #Agent Overview - Export-SCOMAgentOverview
    Write-Host Gather Agent details ...
    $query = @"
select 
bme.path AS 'Agent Name',
 hs.patchlist AS 'Patch List',
 hs.ActionAccountIdentity as 'Action Account',
 hs.InstallTime as 'Installed Date',
 hs.InstalledBy as 'Installed By',
 case when hs.ProxyingEnabled = '1' then 'true'
 else 'false'
 end as 'Proxying',
  case when hs.IsManuallyInstalled = '1' then 'true'
 else 'false'
 end as 'Manually Installed',
 hs.Version as 'Version'
from MT_HealthService hs 
inner join BaseManagedEntity bme on hs.BaseManagedEntityId = bme.BaseManagedEntityId 
where hs.IsAgent = '1'
order by patchlist, bme.path 
"@
    $data = Get-SqlTable -sqlServer $scomSQL.DatabaseServer -sqlDatabase $scomSQL.DatabaseDB -query $query
    $result = $data | Select-Object 'Agent Name', 'Patch List', 'Action Account', 'Installed Date', 'Installed By', 'Proxying', 'Manually Installed', Version
    $htmlOut2 += $result | ConvertTo-Html -fragment -PreContent "`r`n<H2>Agent Overview </H2>`r`n" 

    # Health Service Action Accounts (OperationsManager)* - Export-SCOMActionAccounts
    Write-Host Gather Health service action accounts ...
    $query = @"
Select 
hsvc.IsAgent,
sr.displayname as 'RunAs Profile Name', 
sr.description as 'RunAs Profile Description', 
cmss.name as 'RunAs Account Name', 
cmss.description as 'RunAs Account Description', 
cmss.username as 'RunAs Account Username', 
cmss.domain as 'RunAs Account Domain', 
mp.FriendlyName as 'RunAs Profile MP', 
hsvc.displayname as 'HealthService'
from SecureReference as crh
inner join SecureStorageSecureReference sss on sss.SecureReferenceId = crh.SecureReferenceId
inner join SecureReferenceView sr on sr.Id = sss.SecureReferenceId
inner join CredentialManagerSecureStorage cmss on cmss.securestorageelementID = sss.securestorageelementID 
inner join managementpackview mp on sr.ManagementPackId = mp.Id
inner join BaseManagedEntity bme on bme.basemanagedentityID = sss.healthserviceid
inner join MT_HealthService hsvc on hsvc.BaseManagedEntityId = sss.healthserviceid
order by hsvc.displayname
"@
    $data = Get-SqlTable -sqlServer $scomSQL.DatabaseServer -sqlDatabase $scomSQL.DatabaseDB -query $query
    $result = $data |  Select-Object IsAgent, 'RunAs Profile Name', 'RunAs Profile Description', 'RunAs Account Name', 'RunAs Account Description', 'RunAs Account Username', 'RunAs Account Domain', HealthService, 'RunAs Profile MP'
    $htmlOut3 += $result | ConvertTo-Html -fragment -PreContent "`r`n<H2> Health Service Action Accounts</H2>`r`n" 

    # Get Management Packs (Get-SCOMManagementPack)
    Write-Host Gather management pack info ...
    $result = Get-SCOMManagementPack | Select-Object Version, DisplayName, FriendlyName | Sort-Object DisplayName
    $out = $result | ConvertTo-Html -fragment -PreContent "`r`n<H2>Management Packs</H2>`r`n" 
    $out = $out.replace("<td>", '<td style="width: 1px; white-space: nowrap;">')
    $out = $out.replace("<table>", '<table style="width:auto">')
    $htmlOut4 += $out

    $htmlOut += '<a href="https://kevinholman.com/2017/05/09/scom-management-mp-making-a-scom-admins-life-a-little-easier/">SCOM Management</a><br>' + "`r`n"
    $htmlOut += $end
    $htmlOut2 += $end
    $htmlOut3 += $end
    $htmlOut4 += $end
    $htmlOut | Out-File $outFile
    $htmlOut2 | Out-File $outFile2
    $htmlOut3 | Out-File $outFile3
    $htmlOut4 | Out-File $outFile4

    Invoke-Item $outFile
    Invoke-Item $outFile2
    Invoke-Item $outFile3
    Invoke-Item $outFile4

    Write-Host Data collection complete
} # End of function



<#
    Begin by getting all SCOM Servers and SQL servers. Retrieve SCOM Versions and OS info (plus: CPU's, RAM, drive space)
Get-SCOMManagementServer
Get-SCOMDataWarehouseSetting
"HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\" DatabaseName, DatabaseServerName, DataWarehouseDBName, DataWarehouseDBServerName, CurrentVersion
invoke-command -scriptblock { Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\" } -ComputerName scomms01
"HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Modules\Global\Command Executer\AsyncProcessLimit"
get management server registry settings (https://kevinholman.com/2017/03/08/recommended-registry-tweaks-for-scom-2016-management-servers/)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\HealthService\Parameters" /v "State Queue Items" /t REG_DWORD /d 20480 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\HealthService\Parameters" /v "Persistence Checkpoint Depth Maximum" /t REG_DWORD /d 104857600 /f
reg add "HKLM\SOFTWARE\Microsoft\System Center\2010\Common\DAL" /v "DALInitiateClearPool" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\System Center\2010\Common\DAL" /v "DALInitiateClearPoolSeconds" /t REG_DWORD /d 60 /f
reg add "HKLM\SOFTWARE\Microsoft\System Center\2010\Common" /v "GroupCalcPollingIntervalMilliseconds" /t REG_DWORD /d 1800000 /f
reg add "HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse" /v "Command Timeout Seconds" /t REG_DWORD /d 1800 /f
reg add "HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse" /v "Deployment Command Timeout Seconds" /t REG_DWORD /d 86400 /f
get settings
get DB retention settings
get DW retention settings
get RunAs accounts and profiles
get distribution accounts
get resource pools
get notification information
get SQL server info
$SQLDevices = get-scomclass -Displayname “SQL DB Engine” | get-scomclassinstance
$sqlServers = get-scomgroup -DisplayName "MSSQL: Generic DB Engine Group" | Get-SCOMClassInstance | % { $_.'[Microsoft.SQLServer.Core.DBEngine].MachineName'.value } | sort
Get all Windows, Linux, and Node Agent and OS info
get Management Packs
#>
