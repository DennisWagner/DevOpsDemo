Clear-Host

function Publish-SSAS ($pSsasServerName, [system.io.fileinfo]$pInputFile ) {
    $Path = $pInputFile.Directory 
    $DatabaseName = $pInputFile.BaseName 

    Write-Host "Deploying: $DatabaseName"

    $ConnString = "Provider=MSOLAP.6;Data Source=$pSsasServerName;Integrated Security=SSPI;Impersonation Level=Impersonate"

    # prepare deploy files and copy to input folder
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
                                <Server>$pSsasServerName</Server>
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
    $result = Microsoft.AnalysisServices.Deployment.exe $pInputFile.FullName /s:$DeploymentLogFile /o:$DeploymentXmlaFile

    If (-not (Test-Path -Path $DeploymentXmlaFile)) {
        $log = Get-Content -Path $DeploymentLogFile
        throw "An error occurred during generation of xmla file.`nError from Microsoft.AnalysisServices.Deployment.exe:`n$log"
    }

    # 2. Execute XMLA
    #*********************
    Import-Module sqlascmdlets -Verbose: $false -ErrorAction Stop
		
    $result = Invoke-ASCmd -InputFile $DeploymentXmlaFile -Server $pSsasServerName -Verbose: $false -ErrorAction Stop
}


function Publish-SQL ($pSqlServerName, $pDatabaseName, [system.io.fileinfo]$pInputFile ) {
    $Path = $pInputFile.Directory 
    $FileName = $pInputFile.BaseName 

    Write-Host "Deploying: $FileName"
    
    $location = Get-Location
    
    $output = Invoke-Sqlcmd `
                  -ServerInstance $pSqlServerName `
                  -Database $pDatabaseName `
                  -InputFile $pInputFile.FullName `
                  -OutputSqlErrors $true `
                  -ErrorAction Stop `
    
    Set-Location -Path $location 
}

function Publish-SQL2 ($pSqlServerName, $pDatabaseName, [system.io.fileinfo]$pInputFile ) {
    $Path = $pInputFile.Directory 
    $FileName = $pInputFile.BaseName 
    $Extension = $pInputFile.Extension
    $ArchiveFolder = Join-Path $Path "Arkiv"
    $ArchiveFile = Join-Path $ArchiveFolder $("$FileName$Extension")

    If (-not (Test-Path $ArchiveFile)) {

        Write-Host "Deploying: $FileName"
    
        $location = Get-Location
    
        $output = Invoke-Sqlcmd `
                      -ServerInstance $pSqlServerName `
                      -Database $pDatabaseName `
                      -InputFile $pInputFile.FullName `
                      -OutputSqlErrors $true `
                      -ErrorAction Stop `
                      #-Verbose 
    
        Set-Location -Path $location 

        Copy-Item -path $pInputFile.FullName -destination $ArchiveFolder
    } else
    {
        Write-Host "Skipping: $FileName"
    }
}



function Publish-SSIS ($pSqlServerName, $pFolderName, [system.io.fileinfo]$pInputFile ) {
    $ProjectName = $pInputFile.BaseName
    Write-Host "Deploying: $ProjectName"

    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices") | Out-Null;
    $sqlConnectionString = "Data Source=$pSqlServerName;Initial Catalog=SSISDB;Integrated Security=SSPI;"
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
    $integrationServices = New-Object "Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices" $sqlConnection
		
    $catalog = $integrationServices.Catalogs["SSISDB"]
    $folder = $catalog.Folders[$pFolderName]

    #Deploy project
    [byte[]] $projectFile = [System.IO.File]::ReadAllBytes($pInputFile.FullName)
    $deploy_operation = $folder.DeployProject($ProjectName, $projectFile) #| Out-Null
}








