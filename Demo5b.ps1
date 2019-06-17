Clear-Host

. (Join-Path $PSScriptRoot "funktioner.ps1")

$Env = Read-Host -Prompt 'Hvilket miljø skal der deployes til?'

$Settings = Get-Content $(Join-Path $PSScriptRoot "$Env.settings") | Out-String | ConvertFrom-Json
Write-Host "Settings used:"
$Settings

$SqlServerName = $Settings.SqlServerName
$SsasServerName = $Settings.SsasServerName
$DatabaseName = $Settings.DatabaseName
$FolderName = $Settings.FolderName
$Path = $Settings.Path

#######################################################

Write-Host "SQL:"

$files = Get-ChildItem $Path -Filter *.txt 

ForEach ($InputFile in $files) {
    Publish-SQL $SqlServerName $DatabaseName $InputFile
}


#######################################################

Write-Host "`nSSIS:"

$files = Get-ChildItem $Path -Filter *.ispac 

ForEach ($InputFile in $files) {
    Publish-SSIS $SqlServerName $FolderName $InputFile
}


#######################################################

Write-Host "`nSSAS:"

$files = Get-ChildItem $Path -Filter *.asdatabase 

ForEach ($InputFile in $files) {
    Publish-SSAS $SsasServerName $InputFile
}




