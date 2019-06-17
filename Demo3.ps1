Clear-Host

$SsasServerName = 'localhost\ssas_tab'
$Path = 'e:\MsBip\Release\'

###################################################

$InputFile = [system.io.fileinfo](Join-Path $Path "Praksys BI.asdatabase")

$Path = $InputFile.Directory 
$DatabaseName = $InputFile.BaseName 

Write-Host "Deploying: $DatabaseName"

$ConnString = "Provider=MSOLAP.6;Data Source=$SsasServerName;Integrated Security=SSPI;Impersonation Level=Impersonate"

# prepare deploy files 
$DeploymentOptions = "<DeploymentOptions  
                        xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
                        xmlns:ddl2='http://schemas.microsoft.com/analysisservices/2003/engine/2' xmlns:ddl2_2='http://schemas.microsoft.com/analysisservices/2003/engine/2/2'
                        xmlns:ddl100_100='http://schemas.microsoft.com/analysisservices/2008/engine/100/100' xmlns:ddl200='http://schemas.microsoft.com/analysisservices/2010/engine/200'
                        xmlns:ddl200_200='http://schemas.microsoft.com/analysisservices/2010/engine/200/200'>
                        <TransactionalDeployment>false</TransactionalDeployment>
                        <PartitionDeployment>RetainPartitions</PartitionDeployment>
                        <RoleDeployment>DeployRolesRetainMembers</RoleDeployment>
                        <ProcessingOption>DoNotProcess</ProcessingOption>
                        <OutputScript></OutputScript>
                        <ImpactAnalysisFile></ImpactAnalysisFile>
                        <ConfigurationSettingsDeployment>Retain</ConfigurationSettingsDeployment>
                        <OptimizationSettingsDeployment>Retain</OptimizationSettingsDeployment>
                        <WriteBackTableCreation>UseExisting</WriteBackTableCreation>
                    </DeploymentOptions>"

$DeploymentTargets = "<DeploymentTarget
                        xmlns:xsd='http://www.w3.org/2001/XMLSchema'
                        xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
                        xmlns:ddl2='http://schemas.microsoft.com/analysisservices/2003/engine/2'
                        xmlns:ddl2_2='http://schemas.microsoft.com/analysisservices/2003/engine/2/2'
                        xmlns:ddl100_100='http://schemas.microsoft.com/analysisservices/2008/engine/100/100'
                        xmlns:ddl200='http://schemas.microsoft.com/analysisservices/2010/engine/200'
                        xmlns:ddl200_200='http://schemas.microsoft.com/analysisservices/2010/engine/200/200'>
                        <Database>$DatabaseName</Database>
                        <Server>$SsasServerName</Server>
                        <ConnectionString>$ConnString</ConnectionString>
                    </DeploymentTarget>"
 
$DeploymentOptionsFile = Join-Path $Path "$DatabaseName.deploymentoptions"
$DeploymentTargetsFile = Join-Path $Path "$DatabaseName.deploymenttargets"
$DeploymentXmlaFile = Join-Path $Path "$DatabaseName.xmla"
$DeploymentLogFile = Join-Path $Path "$DatabaseName.log"

$DeploymentOptions | Out-file -FilePath $DeploymentOptionsFile -Force
$DeploymentTargets | Out-file -FilePath $DeploymentTargetsFile -Force

# Make sure the xmla file is not present before deployment, since it's presence is used for error checking.
If (Test-Path -Path $DeploymentXmlaFile) {
    Remove-Item -Path $DeploymentXmlaFile -Force
}
        
# The .asdatabase is not deployed by the Microsoft.AnalysisServices.Deployment tool, because the tool cannot report back errors in a proper manner.
# Instead, the tool is used for generating xmla, which is then executed using the AS commandlet.

# 1. Generate XMLA. 
$result = Microsoft.AnalysisServices.Deployment.exe $InputFile.FullName /s:$DeploymentLogFile /o:$DeploymentXmlaFile

If (-not (Test-Path -Path $DeploymentXmlaFile)) {
    $log = Get-Content -Path $DeploymentLogFile
    throw "An error occurred during generation of xmla file.`nError from Microsoft.AnalysisServices.Deployment.exe:`n$log"
}

# 2. Execute XMLA
#*********************
Import-Module sqlascmdlets -Verbose: $false -ErrorAction Stop
		
$result = Invoke-ASCmd -InputFile $DeploymentXmlaFile -Server $SsasServerName -Verbose: $false -ErrorAction Stop

Write-Host "Result from xmla script execution: $result"

Write-Host "Deployed ssas database:"
$SsasServer = New-Object "Microsoft.AnalysisServices.Server"
$SsasServer.connect($SsasServerName)
$SsasDatabase =  $SsasServer.Databases[$DatabaseName]

$SsasDatabase
$SsasDatabase.DataSources

# https://docs.microsoft.com/en-us/dotnet/api/microsoft.analysisservices?view=sqlserver-2016
