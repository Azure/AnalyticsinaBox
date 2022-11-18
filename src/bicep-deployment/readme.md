![FTA Analytics-in-a-Box: Bicep and CI/CD](/Assets/images/ftaanalyticsinaboxcicd.png)

## <img src ='https://airsblobstorage.blob.core.windows.net/airstream/bicep.png' alt="FTA Analytics-in-a-Box: Bicep Deployment" width="50px" style="float: left; margin-right:10px;"> Bicep Deployment Preparation


### Preparation
1. Install az cli  
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
2. bicep install
https://aka.ms/bicep-install
3. Install Azure Synapse Powershell Module</br>
Install-Module -Name Az.Synapse
4. Bicep install (for Powershell)</br>
[Setup your Bicep development environment](https://github.com/Azure/bicep/blob/main/docs/installing.md#manual-with-powershell)
5. Make sure Microsoft.Synapse Resource Provider is Registered </br>
[Register a Resource Provider](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)

1. Edit parameter File
- main.parameters.json</br>
  - required</br>
  Xx$$x0xx (sqlAdministratorLoginPassword) (At least 12 characters (uppercase, lowercase, and numbers)) </br>
  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -> Your Service Principal ID from Azure AD. Make sure your Service Principal has Ownership role on the subscription.

### (Option)
#### If you use powershell (or pwsh)
1. Install Module Az or Update Module Az  (Az Version >= 5.8.0)
```
 Install-Module Az
```
or
```
Update-Module Az
```
## Usage
### STEP 1
1. Execute PowerShell Prompt
1. Set Parameter(x)

```
Write-Host "hello world"
set-variable -name TenantID "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -option constant
set-variable -name SubscriptionID "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -option constant
set-variable -name BicepFile "main.bicep" -option constant

$parameterFile = "main.parameters.json"
$rgName    = "P1-AnalyticsFundamentals-RG"
$location = "eastus"
```

2. Go to STEP 2 (Azure CLI or PowerShell)
### STEP 2 (PowerShell)
1. Azure Login
```
Connect-AzAccount -Tenant ${TenantID} -Subscription ${SubscriptionID}
```
2. Create Resource Group  
```
New-AzResourceGroup -Name ${rgName} -Location ${location} -Verbose
```
3. Deployment Create  
```
New-AzResourceGroupDeployment `
  -Name AnalyticsFundamentals `
  -ResourceGroupName ${rgName} `
  -TemplateFile ${BicepFile} `
  -TemplateParameterFile ${parameterFile} `
  -Verbose
```

### STEP 2 (Azure CLI)
1. Azure Login
```
az login -t ${TenantID} --verbose
```
2. Set Subscription
```
az account set --subscription ${SubscriptionID} --verbose
```
3. Create Resource Group  
```
az group create --name ${rgName} --location ${location} --verbose
```
4. Deployment Create  
```
az deployment group create --resource-group ${rgName} --template-file ${BicepFile} --parameters ${parameterFile} --verbose
```