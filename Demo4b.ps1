Clear-Host

. (Join-Path $PSScriptRoot "funktioner.ps1")

$SqlServerName = 'localhost'
$SsasServerName = 'localhost\ssas_tab'
$DatabaseName = 'MsBip'
$FolderName = 'MsBip'
$Path = 'e:\MsBip\Release\'

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




