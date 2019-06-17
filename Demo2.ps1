Clear-Host

$SqlServerName = 'localhost'
$FolderName = 'MsBip'
$Path = 'e:\MsBip\Release\'

###################################################

$InputFile = [system.io.fileinfo](Join-Path $Path "DW.Ssis.Load.Dim.Ydl.ispac")

$ProjectName = $InputFile.BaseName
Write-Host "Deploying: $ProjectName"

# LoadWithPartialName is deprecated, but makes it possible
# to target SQL 2014 and 2016 wittout changing the script
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices") | Out-Null;
$sqlConnectionString = "Data Source=$SqlServerName;Initial Catalog=SSISDB;Integrated Security=SSPI;"
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
$integrationServices = New-Object "Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices" $sqlConnection
		
$catalog = $integrationServices.Catalogs["SSISDB"]
$folder = $catalog.Folders[$FolderName]

#Deploy project
[byte[]] $projectFile = [System.IO.File]::ReadAllBytes($InputFile.FullName)
$deploy_operation = $folder.DeployProject($ProjectName, $projectFile) #| Out-Null

Write-Host "Result from deploy:"
$deploy_operation

Write-Host "Deployed project:"
$project = $folder.Projects[$ProjectName]
$project

# https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.integrationservices?redirectedfrom=MSDN&view=sqlserver-2017

