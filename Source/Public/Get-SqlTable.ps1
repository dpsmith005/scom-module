function Get-SqlTable {
  <#
  .Synopsis
    Retrieve a SQL table contents
  .Description
    Run a sql query to retrieve table contents.  The server, database, and query are provided as input parameters.  Optional credentials many be provided.
    This will run the query and return the results or an error message.
  .Parameter sqlServer
    Management server name to begin the data collection.
  .Parameter sqlDatabase
    SQL database name to run query
  .Parameter query
    SQL query to run
  .Parameter credential
    provide credentials is needed
  .Example
    Get-SqlTable -sqlServer sqlserver00 -sqlDatabase DBname -query "Select * from table" -credential (get-credential)
    Provide a SQL servername, database and query
  .Example
    $query = 'select * from table'
    Get-SqlTable -sqlServer sqlserver00 -sqlDatabase DBname -query $query -credential $cred
    store the query in a parameter
    Provide a SQL servername, database and query
  .Notes
    NAME:     Get-SqlTable
    AUTHOR:   David Smith
    LASTEDIT: 19 June 2025
    KEYWORDS:
  #Requires -Version 5.0

  #>
  #[CmdletBinding()]
  Param([Parameter(Mandatory = $true, Position = 0)][string]$sqlServer,
    [Parameter(Mandatory = $true, Position = 1)][string]$sqlDatabase,
    [Parameter(Mandatory = $true, Position = 2)][string]$query,
    [Parameter(Position = 3)][System.Management.Automation.PSCredential]$credential
  )
  try {
    # SQL Connection
    $ConnectionTimeout = 30
    $conn = new-object System.Data.SqlClient.SQLConnection
    if ($PSBoundParameters.ContainsKey('Credential')) {
      #$ConnectionString = "Data Source={0};Initial Catalog={1};Integrated Security=True;Connect Timeout={2};User ID = {3};Password = {4}" -f $sqlServer, $sqlDatabase, $ConnectionTimeout, $credential.UserName, $credential.GetNetworkCredential().password
      $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2};User ID = {3};Password = {4}" -f $sqlServer, $sqlDatabase, $ConnectionTimeout, $credential.UserName, $credential.GetNetworkCredential().password
    }
    else {
      #$ConnectionString = "Server={0};Database={1};Connect Timeout={2}" -f $sqlServer, $sqlDatabase, $ConnectionTimeout
      $ConnectionString = "Data Source={0};Initial Catalog={1};Connect Timeout={2};Integrated Security=true;" -f $sqlServer, $sqlDatabase, $ConnectionTimeout
    }
    #$conn.ConnectionString="Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $server,$database,$ConnectionTimeout
    $conn.ConnectionString = $ConnectionString
    $conn.Open()

    # Query details
    $QueryTimeout = 120
  
    # Create the cmd connection
    $cmd = new-object system.Data.SqlClient.SqlCommand($Query, $conn)
    $cmd.CommandTimeout = $QueryTimeout


    $ds = New-Object system.Data.DataSet
    $da = New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    [void]$da.fill($ds)
    $data = $ds.Tables[0].rows
    $conn.Close()
    $conn.Dispose()
    Remove-Variable conn -ErrorAction SilentlyContinue
  
  }
  catch {
    $msg = "Unable to connect to server $sqlServer to database $sqlDatabase"
    Write-Error $msg 
    return $msg
  }
  return $data
  # $query = 'SELECT * FROM  [TechServices].[dbo].[ServerTrackingDaily]'
}