Clear-Host

. (Join-Path $PSScriptRoot "funktioner.ps1")

$SqlServerName = 'localhost'
$SsasServerName = 'localhost\ssas_tab'
$DatabaseName = 'MsBip'
$FolderName = 'MsBip'
$Path = 'e:\MsBip\Release\'

#######################################################

Write-Host "SQL:"

$InputFile = [system.io.fileinfo](Join-Path $Path 'sql2.txt')

Publish-SQL $SqlServerName $DatabaseName $InputFile

#######################################################

Write-Host "`nSSIS:"

$InputFile = [system.io.fileinfo](Join-Path $Path 'DW.Ssis.Load.Dim.Ydl.ispac')

Publish-SSIS $SqlServerName $FolderName $InputFile

#######################################################

Write-Host "`nSSAS:"

$InputFile = [system.io.fileinfo](Join-Path $Path 'Praksys BI.asdatabase')

Publish-SSAS $SsasServerName $InputFile




