<#
 .NOTES
        =========================================================================================================
        Created by:       Author: Analytics Fundamentals - FTA Toolkit Team
        Created on:       09/13/2022
        =========================================================================================================

 .DESCRIPTION
        You can run the script one of two ways:
        1. Using Inline Parameters
                .\SynapseDeployArtifacts.ps1 -SubscriptionID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -ResourceGroupName P2-AnalyticsFundamentals-RG -ResourceGroupLocation eastus -KeyVaultName ftatoolkit-keyvault-xxx -KeyVaultID /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/P2-AnalyticsFundamentals-RG/providers/Microsoft.KeyVault/vaults/ftatoolkit-keyvault-xxx -SynapseWorkspaceName ftatoolkit-synapse-xxx -SynapseWorkspaceID /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/P2-AnalyticsFundamentals-RG/providers/Microsoft.Synapse/workspaces/ftatoolkit-synapse-xxx -DataLakeAccountName ftatoolkitadlsxxx -DataLakeAccountResourceID /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/P2-AnalyticsFundamentals-RG/providers/Microsoft.Storage/storageAccounts/ftatoolkitadlsxxx -AzureSQLServerName ftatoolkit-sql-xxx -UAMIPrincipalID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -CtrlDeploySampleArtifacts $True -SampleArtifactCollectioName OpenDatasets
#>

#---------------------------------------------------------[Parameters]-----------------------------------------------------
#region Parameters
param(
  [string] $SubscriptionID,
  [string] $ResourceGroupName,
  [string] $ResourceGroupLocation,
  [string] $SynapseWorkspaceName,
  [string] $SynapseWorkspaceID,
  [string] $DataLakeAccountName,
  [string] $DataLakeAccountResourceID,
  [string] $KeyVaultName,
  [string] $KeyVaultID,
  [string] $AzureSQLServerName,
  [string] $UAMIPrincipalID,
  [Parameter(Mandatory=$false)]
  [bool] $CtrlDeploySampleArtifacts,
  [AllowEmptyString()]
  [Parameter(Mandatory=$false)]
  [string] $SampleArtifactCollectioName
)

#>
#endregion Parameters

Clear-Host

#------------------------------------------------------------------------------------------------------------
# FUNCTION DEFINITIONS
#------------------------------------------------------------------------------------------------------------
function Set-SynapseControlPlaneOperation{
  param (
    [string] $SynapseWorkspaceID,
    [string] $HttpRequestBody
  )

  $uri = "https://management.azure.com$SynapseWorkspaceID`?api-version=2021-06-01"
  $token = (Get-AzAccessToken -Resource "https://management.azure.com").Token
  $headers = @{ Authorization = "Bearer $token" }

  $retrycount = 1
  $completed = $false
  $secondsDelay = 60

  while (-not $completed) {
    try {
      Invoke-RestMethod -Method Patch -ContentType "application/json" -Uri $uri -Headers $headers -Body $HttpRequestBody -ErrorAction Stop
      Write-Host "Control plane operation completed successfully."
      $completed = $true
    }
    catch {
      if ($retrycount -ge $retries) {
          Write-Host "Control plane operation failed the maximum number of $retryCount times."
          Write-Warning $Error[0]
          throw
      } else {
          Write-Host "Control plane operation failed $retryCount time(s). Retrying in $secondsDelay seconds."
          Write-Warning $Error[0]
          Start-Sleep $secondsDelay
          $retrycount++
      }
    }
  }
}

function Save-SynapseLinkedService{
  param (
    [string] $SynapseWorkspaceName,
    [string] $LinkedServiceName,
    [string] $LinkedServiceRequestBody
  )

  [string] $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/linkedservices/$LinkedServiceName"
  $uri += "?api-version=2019-06-01-preview"

  Write-Host "Creating Linked Service [$LinkedServiceName]..."
  $retrycount = 1
  $completed = $false
  $secondsDelay = 60

  while (-not $completed) {
    try {
      Write-Host "URI: $uri"
      Write-Host "Body: $LinkedServiceRequestBody"
      Write-Host "Headers: $headers"

      Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $LinkedServiceRequestBody -ErrorAction Stop
      Write-Host "Linked service [$LinkedServiceName] created successfully."
      $completed = $true
    }
    catch {
      if ($retrycount -ge $retries) {
          Write-Host "Linked service [$LinkedServiceName] creation failed the maximum number of $retryCount times."
          Write-Warning $Error[0]
          throw
      } else {
          Write-Host "Linked service [$LinkedServiceName] creation failed $retryCount time(s). Retrying in $secondsDelay seconds."
          Write-Warning $Error[0]
          Start-Sleep $secondsDelay
          $retrycount++
      }
    }
  }
}

function Save-SynapseSampleArtifacts{
  param (
      [string] $SynapseWorkspaceName,
      [string] $SampleArtifactCollectionName
  )

  #Install Synapse PowerShell Module
  #You need to install latest Az.Synapse module and make sure that Az.Account Module is at least at Version 2.10
  if (Get-Module -ListAvailable -Name "Az.Synapse") {
    Write-Host "PowerShell Module Az.Synapse already installed."
  }
  else {
    Install-Module Az.Synapse -Force
    Import-Module Az.Synapse
  }

  #Add System.Web type to encode/decode URL
  Add-Type -AssemblyName System.Web

  #Authenticate for REST API calls
  $token = (Get-AzAccessToken -Resource "https://dev.azuresynapse.net").Token
  $headers = @{ Authorization = "Bearer $token" }

  $synapseTokens = @{"`#`#azsynapsewks`#`#" = $SynapseWorkspaceName; }
  $indexFileUrl = "https://raw.githubusercontent.com/AndresPad/FTAToolkitArtifacts/main/Sample/index.json"
  #$indexFileUrl = "index.json"
  #$sampleCodeIndex = Get-Content -Raw -Path index.json | ConvertFrom-Json
  $sampleCodeIndex = Invoke-WebRequest $indexFileUrl | ConvertFrom-Json

  Write-Host "Deploying SynapseSampleArtifacts:"

  foreach($sampleArtifactCollection in $sampleCodeIndex)
  {
    if ($sampleArtifactCollection.template -eq $SampleArtifactCollectionName) {
      Write-Host "Deploying Sample Artifact Collection: $($sampleArtifactCollection.template)"
      Write-Host "-----------------------------------------------------------------------"

      #Create SQL Script artifacts.
      #----------------------------------------------------------------------------------
      Write-Host "Deploying SQL Scripts:"
      Write-Host "-----------------------------------------------------------------------"

      foreach($sqlScript in $sampleArtifactCollection.artifacts.sqlScripts)
      {
        $fileContent = Invoke-WebRequest $sqlScript.definitionFilePath

        if ($sqlScript.tokens.length -gt 0) {
          foreach($token in $sqlScript.tokens)
          {
              $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
          }
        }

        if ($sqlScript.interface.ToLower() -eq "powershell") {
          Write-Host "Creating SQL Script: $($sqlScript.name) via PowerShell"
          $definitionFilePath = [guid]::NewGuid()
          Set-Content -Path $definitionFilePath $fileContent
          Set-AzSynapseSqlScript -WorkspaceName $SynapseWorkspaceName -Name $sqlScript.name -DefinitionFile $definitionFilePath -FolderPath $sqlScript.workspaceFolderPath
          Remove-Item -Path $definitionFilePath
        }
        elseif ($sqlScript.interface.ToLower() -eq "rest")
        {
            Write-Host "Creating SQL Script: $($sqlScript.name) via REST API"
            $subresource = "sqlScripts"
            $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/$subresource/$($sqlScript.name)?api-version=2020-02-01"

            #Assign Synapse Workspace Administrator Role to UAMI
            $body = $fileContent
            Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body
        }
      }

      #Create Linked Service artifacts.
      #----------------------------------------------------------------------------------
      Write-Host "-----------------------------------------------------------------------"
      Write-Host "Deploying Linked Service:"
      Write-Host "-----------------------------------------------------------------------"

      foreach($linkedService in $sampleArtifactCollection.artifacts.linkedServices)
      {
        $fileContent = Invoke-WebRequest $linkedService.definitionFilePath

        if ($linkedService.tokens.length -gt 0) {
            foreach($token in $linkedService.tokens)
            {
                $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
            }
        }

        $definitionFilePath = [guid]::NewGuid()
        Set-Content -Path $definitionFilePath $fileContent
        Set-AzSynapseLinkedService -WorkspaceName $SynapseWorkspaceName -Name $linkedService.name -DefinitionFile $definitionFilePath
        Remove-Item -Path $definitionFilePath
      }

      #Create Dataset artifacts.
      #----------------------------------------------------------------------------------
      Write-Host "-----------------------------------------------------------------------"
      Write-Host "Deploying Datasets:"
      Write-Host "-----------------------------------------------------------------------"

      foreach($dataset in $sampleArtifactCollection.artifacts.datasets)
      {
        $fileContent = Invoke-WebRequest $dataset.definitionFilePath

        if ($dataset.tokens.length -gt 0) {
            foreach($token in $dataset.tokens)
            {
                $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
            }
        }

        $definitionFilePath = [guid]::NewGuid()
        Set-Content -Path $definitionFilePath $fileContent
        Set-AzSynapseDataset -WorkspaceName $SynapseWorkspaceName -Name $dataset.name -DefinitionFile $definitionFilePath
        Remove-Item -Path $definitionFilePath
      }

      #Create Dataflows artifacts.
      #----------------------------------------------------------------------------------
      Write-Host "-----------------------------------------------------------------------"
      Write-Host "Deploying Dataflows:"
      Write-Host "-----------------------------------------------------------------------"

      foreach($dataflow in $sampleArtifactCollection.artifacts.dataflows)
      {
        $fileContent = Invoke-WebRequest $dataflow.definitionFilePath

        if ($dataflow.tokens.length -gt 0) {
            foreach($token in $dataflow.tokens)
            {
                $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
            }
        }

        $definitionFilePath = [guid]::NewGuid()
        Set-Content -Path $definitionFilePath $fileContent
        Set-AzSynapseDataFlow -WorkspaceName $SynapseWorkspaceName -Name $dataflow.name -DefinitionFile $definitionFilePath
        Remove-Item -Path $definitionFilePath
      }

      #Create Pipeline artifacts.
      #----------------------------------------------------------------------------------
      Write-Host "-----------------------------------------------------------------------"
      Write-Host "Deploying Pipelines:"
      Write-Host "-----------------------------------------------------------------------"

      foreach($pipeline in $sampleArtifactCollection.artifacts.pipelines)
      {
        $fileContent = Invoke-WebRequest $pipeline.definitionFilePath

        if ($pipeline.tokens.length -gt 0) {

            foreach($token in $pipeline.tokens)
            {
                $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
            }
        }

        $definitionFilePath = [guid]::NewGuid()
        Set-Content -Path $definitionFilePath $fileContent
        Set-AzSynapsePipeline -WorkspaceName $SynapseWorkspaceName -Name $pipeline.name -DefinitionFile $definitionFilePath
        Remove-Item -Path $definitionFilePath
      }

      #Create Notebook artifacts.
      #----------------------------------------------------------------------------------
      Write-Host "-----------------------------------------------------------------------"
      Write-Host "Deploying Notebooks:"
      Write-Host "-----------------------------------------------------------------------"

      foreach($notebook in $sampleArtifactCollection.artifacts.notebooks)
      {
        $fileContent = Invoke-WebRequest $notebook.definitionFilePath

        if ($notebook.tokens.length -gt 0) {
          foreach($token in $notebook.tokens)
          {
              $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
          }
        }

        if ($notebook.interface.ToLower() -eq "powershell") {
          $definitionFilePath = [guid]::NewGuid()
          Set-Content -Path $definitionFilePath $fileContent
          Set-AzSynapseNotebook -WorkspaceName $SynapseWorkspaceName -Name $notebook.name -DefinitionFile $definitionFilePath -FolderPath $notebook.workspaceFolderPath
          Remove-Item -Path $definitionFilePath
        }
        elseif ($notebook.interface.ToLower() -eq "rest") {
          ## Action to perform if the condition is true #>
        }
      }
      break
    }
  }
}

$retries = 10
$secondsDelay = 60
#---------------------------------------------------------[Entry Point - Execution of Script Starts Here]-----------------------------------------------------
#region Entry Point - MAIN SCRIPT BODY
Write-Host "#--------------------------------------------------------------------------------------------------------";
    Write-Host "  Analytics Fundamentals - Synapse Analytics Workspace Artifacts Creation" -ForegroundColor Gray
    Write-Output "  Display Params"

    $output = 'Your Params {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}' -f $SubscriptionID, $ResourceGroupName, $ResourceGroupLocation, $SynapseWorkspaceName, $SynapseWorkspaceID, $DataLakeAccountName, $DataLakeAccountResourceID, $KeyVaultName, $KeyVaultID, $AzureSQLServerName, $UAMIPrincipalID

    Write-Host "    SubscriptionID: $SubscriptionID "
    Write-Host "    ResourceGroupName: $ResourceGroupName "
    Write-Host "    ResourceGroupLocation: $ResourceGroupLocation "
    Write-Host "    SynapseWorkspaceName: $SynapseWorkspaceName "
    Write-Host "    SynapseWorkspaceID: $SynapseWorkspaceID "
    Write-Host "    DataLakeAccountName: $DataLakeAccountName "
    Write-Host "    DataLakeAccountResourceID: $DataLakeAccountResourceID "
    Write-Host "    KeyVaultName: $KeyVaultName "
    Write-Host "    KeyVaultID: $KeyVaultID "
    Write-Host "    AzureSQLServerName: $AzureSQLServerName "
    Write-Host "    UAMIPrincipalID: $UAMIPrincipalID "

    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs['text'] = $output

#------------------------------------------------------------------------------------------------------------
# CONTROL PLANE OPERATION: ASSIGN SYNAPSE WORKSPACE ADMINISTRATOR TO USER-ASSIGNED MANAGED IDENTITY
# UAMI needs Synapse Admin rights before it can make calls to the Data Plane APIs to create Synapse objects
#------------------------------------------------------------------------------------------------------------

$token = (Get-AzAccessToken -Resource "https://dev.azuresynapse.net").Token
$headers = @{ Authorization = "Bearer $token" }

$uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/rbac/roleAssignments?api-version=2020-02-01-preview"

#Assign Synapse Workspace Administrator Role to UAMI
$body = "{
  roleId: ""6e4bf58a-b8e1-4cc3-bbf9-d73143322b78"",
  principalId: ""$UAMIPrincipalID""
}"

Write-Host "Assign Synapse Administrator Role to UAMI..."
Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

#------------------------------------------------------------------------------------------------------------
# DATA PLANE OPERATION: CREATE AZURE KEY VAULT LINKED SERVICE
#------------------------------------------------------------------------------------------------------------

#Create AKV Linked Service. Linked Service name same as Key Vault's.
$body = "{
  name: ""$KeyVaultName"",
  properties: {
      annotations: [],
      type: ""AzureKeyVault"",
      typeProperties: {
          baseUrl: ""https://$KeyVaultName.vault.azure.net/""
      }
  }
}"

Write-Host "Create AKV Linked Service..."
Save-SynapseLinkedService $SynapseWorkspaceName $KeyVaultName $body

#Create a Second AKV Linked Service that uses parameters to connect to the Key Vault created through the bicep
$body = "{
  name: ""$KeyVaultName-with-params"",
  properties: {
    parameters: {
			keyVaultName: {
				type: ""string"",
        defaultValue: ""$KeyVaultName""
			}
		},
    annotations: [],
    type: ""AzureKeyVault"",
    typeProperties: {
      baseUrl: ""@{concat('https://',linkedService().keyVaultName,'.vault.azure.net/')}""
    }
  }
}"

Write-Host "Create AKV Linked Service with parameters..."
Save-SynapseLinkedService $SynapseWorkspaceName "$KeyVaultName-with-params" $body

#------------------------------------------------------------------------------------------------------------
# DATA PLANE OPERATION: CREATE ADLS LINKED SERVICE
#------------------------------------------------------------------------------------------------------------
 $dataLakeAccountNames = @($DataLakeAccountName)
 $dataLakeDFSEndpoints = @("https://$DataLakeAccountName.dfs.core.windows.net")

 for ($i = 0; $i -lt $dataLakeAccountNames.Length; $i++) {

  $body = "{
    name: ""$($dataLakeAccountNames[$i])"",
    properties: {
      annotations: [],
      type: ""AzureBlobFS"",
      typeProperties: {
        url: ""$($dataLakeDFSEndpoints[$i])""
      },
      connectVia: {
        referenceName: ""AutoResolveIntegrationRuntime"",
        type: ""IntegrationRuntimeReference""
      }
    }
  }"

  Write-Host "Create DataLake Linked Service..."
  Save-SynapseLinkedService $SynapseWorkspaceName $DataLakeAccountName $body
}

$body = "{
  name: ""TripFaresDataLakeStorageLS"",
  properties: {
    parameters: {
      keyVaultName: {
        type: ""string"",
        defaultValue: ""$KeyVaultName""
      },
      datalakeAccountName: {
        type: ""string"",
        defaultValue: ""$DataLakeAccountName""
      }
    },
    annotations: [],
    type: ""AzureBlobFS"",
    typeProperties: {
      url: ""@{concat('https://',linkedService().datalakeAccountName,'.dfs.core.windows.net')}"",
      accountKey: {
        type: ""AzureKeyVaultSecret"",
        store: {
            referenceName: ""keyVaultLinkedservice"",
            type: ""LinkedServiceReference"",
            parameters: {
                keyVaultName: {
                    value: ""@linkedService().keyVaultName"",
                    type: ""Expression""
                }
            }
        },
        secretName: ""ADLS--AccountKey""
      }
    },
    connectVia: {
      referenceName: ""AutoResolveIntegrationRuntime"",
      type: ""IntegrationRuntimeReference""
    }
  }
}"

Write-Host "Create DataLake Linked Service..."
Save-SynapseLinkedService $SynapseWorkspaceName "TripFaresDataLakeStorageLS" $body

#upload sample csv to public container of newly created storage account
$secret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name "ADLS--AccountKey" -AsPlainText
$context = New-AzStorageContext -StorageAccountName $DataLakeAccountName -StorageAccountKey $secret
Start-AzStorageBlobCopy -AbsoluteUri "https://raw.githubusercontent.com/Azure/Test-Drive-Azure-Synapse-with-a-1-click-POC/main/tripDataAndFaresCSV/trip-data.csv" -DestContainer "public" -DestBlob "trip-data.csv" -DestContext $context -Force
Start-AzStorageBlobCopy -AbsoluteUri "https://raw.githubusercontent.com/Azure/Test-Drive-Azure-Synapse-with-a-1-click-POC/main/tripDataAndFaresCSV/fares-data.csv" -DestContainer "public" -DestBlob "fares-data.csv" -DestContext $context -Force

#------------------------------------------------------------------------------------------------------------
# DATA PLANE OPERATION: CREATE SQL SERVER LINKED SERVICE
#------------------------------------------------------------------------------------------------------------
$sqlAccountName = $AzureSQLServerName -replace ("-","_")

Write-Host "AzureSQLServerName: $AzureSQLServerName"

$body = "{
  name: ""$($AzureSQLServerName)"",
    properties: {
      annotations: [],
      type: ""AzureSqlDatabase"",
      typeProperties: {
        connectionString: {
          type: ""AzureKeyVaultSecret"",
          store: {
          referenceName: ""$KeyVaultName"",
          type: ""LinkedServiceReference""
        },
        secretName: ""ConnectionStrings--CnxDB""
      }
    },
    connectVia: {
      referenceName: ""AutoResolveIntegrationRuntime"",
      type: ""IntegrationRuntimeReference""
    },
    description: ""This link service connects to the sql server sampldb  database...""
  }
}"

Save-SynapseLinkedService $SynapseWorkspaceName $AzureSQLServerName $body

#------------------------------------------------------------------------------------------------------------
# DATA PLANE OPERATION: DEPLOY SAMPLE ARTIFACTS
# Deploy sample artifcats (SQL Scripts, Datasets, Linked Services, Pipelines and Notebooks) based on chosen template.
#------------------------------------------------------------------------------------------------------------

if ($CtrlDeploySampleArtifacts) {
  Save-SynapseSampleArtifacts $SynapseWorkspaceName $SampleArtifactCollectioName
}
#endregion Entry Point