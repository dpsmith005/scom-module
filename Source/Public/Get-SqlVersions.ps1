function Get-SqlVersions {
    <#
  .Synopsis
    Retrieve a SQL table contents
  .Description
    Run a sql query to retrieve table contents.  The server, database, and query are provided as input parameters.  Optional credentials many be provided.
    This will run the query and return the results or an error message.
    .Parameter sqlServers
    Management server name to begin the data collection.
    .Example
    Get-SqlVersion -sqlServers sqlserver00, sqlserver01
    Provide a list of sql servers to query
    .Example
    Get-SqlVersion sqlserver00, sqlserver01
    Provide a list of sql servers to query without the parameter
    .Example
    Get-SqlVersion sqlserver00
    Provide a single sql server to query 
    .Example
    $sqlServers = get-scomgroup -DisplayName "MSSQL: Generic DB Engine Group" | Get-SCOMClassInstance | % { $_.'[Microsoft.SQLServer.Core.DBEngine].MachineName'.value } | sort
    Get-SqlVersion $sqlServers
    Pass the list of SQL servers in SCOM to get all the versions
    .Notes
    NAME:     Get-SqlVersion
    AUTHOR:   David Smith
    LASTEDIT: 19 June 2025
    KEYWORDS:
  #Requires -Version 5.0
#>
    param([Parameter(Mandatory = $true)][string[]]$sqlServers)

    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
    add-type -AssemblyName "Microsoft.SqlServer.SqlWmiManagement, version=11.0.0.0, Culture=Neutral, PublicKeyToken=89845dcd8080cc91";
    #add-type -AssemblyName "Microsoft.AnalysisServices, version=11.0.0.0, Culture=Neutral, PublicKeyToken=89845dcd8080cc91";

    $dataTable = New-Object "system.data.datatable";
    $col = New-Object "system.data.datacolumn" ('MachineName', [System.String]);
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('Release_Name', [System.String]);
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('Type', [System.String]); #type=SQLServer / AnalysisServer / ReprtServer / IntegrationService 
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('DisplayName', [System.String]);
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('Version', [System.String]);
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('Edition', [System.String]);
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('ServiceAccount', [System.String]);
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('Status', [System.String]);
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('StartMode', [System.String]);
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('State', [System.String]);
    $dataTable.columns.Add($col);
    $col = New-Object "system.data.datacolumn" ('Started', [System.String]);
    $dataTable.columns.Add($col);

    foreach ($ServerName in $sqlServers) {
        try {
            Write-host Server $ServerName
            #$mc = new-object "Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer" $ServerName;
            #$services = $mc.services | Where-Object { ($_.type -in ("SqlServer", "AnalysisServer", "ReportServer", 'SqlServerIntegrationService') ) -and ($_.ServiceState -eq 'Running') }
            $services = Get-CimInstance win32_service -ComputerName $ServerName -Filter "name like '%SQL%'" | Select-Object SystemName, Name, DisplayName, Caption, Status, StartMode, State, Started, StartName
            foreach ($service in $services) { 
                $s = $service.name;
                Write-host Service $s
                if ($s.contains("$")) { $sql_instance = "$($ServerName)\$($s.split('$')[1])" } else { $sql_instance = $ServerName; } 
                $sql_svr = new-object "microsoft.sqlserver.management.smo.server" $sql_instance;
                switch ($sql_svr.Version.Major) {
                    17 { $sqlVerName = 'SQL Server 2025'; break; }
                    16 { $sqlVerName = 'SQL Server 2022'; break; }
                    15 { $sqlVerName = 'SQL Server 2019'; break; }
                    14 { $sqlVerName = 'SQL Server 2017'; break; }
                    13 { $sqlVerName = 'SQL Server 2016'; break; }
                    12 { $sqlVerName = 'SQL Server 2014'; break; }
                    11 { $sqlVerName = 'SQL Server 2012'; break; }
                }
                $row = $dataTable.NewRow();
                $row.Edition = $sql_svr.Edition; 
                $row.Version = $sql_svr.Version;
                $row.Type = $service.Name;
                $row.DisplayName = $service.DisplayName
                $row.Release_Name = $sqlVerName;
                $row.ServiceAccount = $service.StartName;
                $row.MachineName = $ServerName;
                $row.Status = $service.Status 
                $row.StartMode = $service.StartMode;
                $row.State = $service.State;
                $row.Started = $service.Started;
                $dataTable.Rows.Add($row); 
            }
        }#try
        catch {
            Write-Error ERROR: $Error[0].Exception
            return $Error[0].Exception
        }
    }#foreach
    $results = $datatable | Select-Object MachineName, Release_Name, Type, DisplayName, Version, Edition, Started, StartMode, State, Status, ServiceAccount
    return $results
}