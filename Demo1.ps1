Clear-Host

$SqlServerName = 'localhost'
$DatabaseName = 'MsBip'
$Path = 'e:\MsBip\Release\'

###################################################

$InputFile = [system.io.fileinfo](Join-Path $Path 'sql2.txt')

$FileName = $InputFile.BaseName 
Write-Host "Deploying: $FileName"

# prevent 'bug' in Invoke-Sqlcmd to set location to SQLSERVER
# should no longer exist in sql 2016
$location = Get-Location

$output = Invoke-Sqlcmd `
                -ServerInstance $SqlServerName `
                -Database $DatabaseName `
                -InputFile $InputFile.FullName `
                -OutputSqlErrors $true `
                -ErrorAction Stop `

Set-Location -Path $location
                
Write-Host "Display output from query:"
$output 

# https://docs.microsoft.com/en-us/powershell/module/sqlserver/invoke-sqlcmd?view=sqlserver-ps
