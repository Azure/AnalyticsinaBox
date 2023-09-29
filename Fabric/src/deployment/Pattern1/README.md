# Tutorial: Build Metadata Driven Pipelines in Microsoft Fabric

## Description
Metadata-driven pipelines in Azure Data Factory, Synapse Pipelines, and now, Microsoft Fabric, give you the capability to ingest and transform data with less code, reduced maintenance and greater scalability than writing code or pipelines for every data source that needs to be ingested and transformed. The key lies in identifying the data loading and transformation pattern(s) for your data sources and destinations and then building the framework to support each pattern.

In August 2023, I created 2 blog posts on Metadata Driven Pipelines with Fabric. Both involve landing the data in a Fabric Lakehouse and building a Star Schema for the Gold Layer. [The first post](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/metadata-driven-pipelines-for-microsoft-fabric/ba-p/3891651) illustrates creating the Star Schema in a Fabric Lakehouse. [The second post](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/metadata-driven-pipelines-for-microsoft-fabric-part-2-data/ba-p/3906749) covers using a Fabric Data Warehouse for the Star Schema and why you may want to choose this option. 

This tutorial is a companion to the Metadata Driven Pipelines in Fabric posts. The intent is to provide step-by-step instructions on how to build the Metadata Driven Pipelines described in those blogs. The reason is 2-fold - this will help you better understand Microsoft Fabric, but also because Fabric is not fully integrated with Git at this time. There are no ARM templates to deploy like in Azure Synapse or Data Factory. However, when Fabric supports Git integration with Pipelines and Connections, we will create another pattern which will allow you deploy all Fabric artifacts into your own Fabric tenant.
## Architecture
Below is a high level architecture diagram of what you will build in this tutorial:

![fabric_architecture](images/fabric_metadata_architecture.jpg)
## Prerequisites
* Permissions to create an Azure Resource Group, Azure Storage Account, Azure SQL Server and Azure SQL DBs
* Permissions to create a Microsoft Fabric Workspace
* Azure DevOps Organization
* SQL Server Management Studio or Azure Data Studio
## Create Resources
1. **Create an Azure Resource group** 
    1. [Follow the instructions here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal), if neccessary, to create your resource group.
1. **Create an Azure Storage account**
    1. Create a blob storage account in the resource group created in the previous step. [Follow the instructions here](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal),if necessary, to create your blob storage account.
1. **Create an Azure SQL Server**
    1. In the Azure Portal, in **Create a resource**, choose **SQL Server** and click **Create.**
    1. Choose your **subscription**
    1. Choose you **resource group** you created in the previous step
    1. Enter a **Server name** - note this must be unique across all azure
    1. Choose your **location**
    1. For authentication method, select **Use both SQL and Microsoft authentication**
    1. Click the **Set admin** button and select your user account
    1. Enter a **Server admin login and password**. Your screen should similar to the one below.
       ![create-sql-server1](images/create-sqlserver-1.jpg)
    1. Navigate to the **Networking** tab and change the slider under Firewall rules to **Yes** to allow Azure services and resources to access this server.
      ![create-sql-server2](images/create-sqlsserver-2.jpg)
    1. Select **Review + create**
1. **Create an Azure SQL DB for Metadata Driven Pipeline Configurations**
    1. Go to the Azure SQL Server you created in the previous step and click **Create database**
    ![sqldb1](images/create-sqldb-1.jpg)
    1. Make sure your resource group and SQL server are selected. Enter **FabricMetadataOrchestration** for the database name.
    1. For **Workload environment** Choose **Development**
    ![sqldb2](images/create-sqldb-2.jpg)
    1. Navigate to **Networking** and under **Firewall rules**, move slider for **Add current client IP address** to **Yes**
    ![sqldb3](images/create-sqldb-3.jpg)
    1. Click **Review and create**
1. **Download and restore the Wide World Importers Database**
    1. Download the Wide World Importers Database for Azure SQL DB. [Click here to immediately download the bacpac](https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac)
    1. Upload the bacpac to the storage account created previously and restore the Wide World Importers database. [Follow the instructions here](https://learn.microsoft.com/en-us/azure/azure-sql/database/database-import?view=azuresql&tabs=azure-powershell), if necessary, to restore the database from the bacpac.
1. **Create an Azure DevOps Repo**
    1. [Follow the instructions here](https://learn.microsoft.com/en-us/azure/devops/repos/git/create-new-repo?view=azure-devops), if necessary, to create an Azure DevOps Repo. This will be used with Git Integration in Fabric.
1. **Create a Microsoft Fabric workspace and configure git integration**
    1. [Create a Fabric Workspace](https://learn.microsoft.com/en-us/fabric/get-started/create-workspaces)
    1. [Configure the Fabric Workspace](https://learn.microsoft.com/en-us/fabric/cicd/git-integration/git-get-started?tabs=commit-to-git) for git
1. **Create Bronze and Gold Fabric Lakehouses**
    1. Create 2 [Microsoft Fabric Lakehouses](https://learn.microsoft.com/en-us/fabric/data-engineering/create-lakehouse) in you workspace.
    1. After creating the Lakehouses, copy the lakehouse names and Table URLs and keep for your reference. 
        1. To get the URLs, open each Lakehouse and click on the ellipses next to the **Tables** folder. Choose **Properties** and copy the abfss file path.
     ![getlakehouse](images/get_lakehouse_url.jpg)
        1. Paste each into notepad or a word document and demove the "/Tables" from the end of the string. Your string will look something like abfss://\<uniqueid>@onelake.dfs.fabric.microsoft.com/a\<anotheruniqueid>
1. **Create a Fabric Data Warehouse**
    1. Create a Fabric Data Warehouse by [following the instructions here](https://learn.microsoft.com/en-us/fabric/data-warehouse/create-warehouse)
1. **Create Fabric Connections to your Azure SQL DBs**
    1. Create 2 Fabric connections, one to the Wide World Importers database and FabricMetadataConfiguration database. {Follow the instructions here](https://learn.microsoft.com/en-us/fabric/data-factory/connector-azure-sql-database) to create the connections to the 2 Azure SQL DBs.
## Create SQL Objects
1. **Create Objects in Wide World Importers Database**
    1. Connect to the Wide World Importers Database in SQL Server Management Studio
    1. Download the SQL scripts found in [in this repo](src/sql/1-wwi/create_source_views.sql) to create views used in this tutorial.
    1. Connect to the FabricMetadataOrchestration database 