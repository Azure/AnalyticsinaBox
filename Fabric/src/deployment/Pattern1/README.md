# Solution Guide: Build Metadata Driven Pipelines in Microsoft Fabric

## Description

Metadata-driven pipelines in Azure Data Factory, Synapse Pipelines, and now, Microsoft Fabric, give you the capability to ingest and transform data with less code, reduced maintenance and greater scalability than writing code or pipelines for every data source entity that needs to be ingested and transformed. The key lies in identifying the data loading and transformation pattern(s) for your data sources and destinations and then building the framework to support each pattern.

In August 2023, I created 2 blog posts on Metadata Driven Pipelines with Fabric. Both involve landing the data in a Fabric Lakehouse and building a Star Schema for the Gold Layer. [The first post](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/metadata-driven-pipelines-for-microsoft-fabric/ba-p/3891651) illustrates creating the Star Schema in a Fabric Lakehouse. [The second post](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/metadata-driven-pipelines-for-microsoft-fabric-part-2-data/ba-p/3906749) covers using a Fabric Data Warehouse for the Star Schema and why you may want to choose this option. 

This solution guide is a companion to the Metadata Driven Pipelines in Fabric posts. The intent is to provide step-by-step instructions on how to build the Metadata Driven Pipelines described in those blogs. The reason is 2-fold - this will help you better understand Microsoft Fabric, but also because Fabric is not fully integrated with Git at this time. There are no ARM templates to deploy like in Azure Synapse or Data Factory. However, when Fabric supports Git integration with Pipelines and Connections, we will create another pattern which will allow you deploy all Fabric artifacts into your own Fabric tenant.

## Architecture

Below is a high level architecture diagram of what you will build in this solution: ![fabric_architecture](images/fabric_metadata_architecture.jpg)
## Prerequisites
* Permissions to create the Azure Resource Group, Azure Storage Account, Azure SQL Server and Azure SQL DBs needed for this tutorial.
* Permissions to create a Microsoft Fabric Workspace
* SQL Server Management Studio or Azure Data Studio
* Basic understanding of creating data pipelines, either from Azure Data Factory, Synapse Analytics or Microsoft Fabric.
## Create Azure Resources
Create an Azure Resource Group, Storage Account, and Azure SQL DBs needed for this tutorial.
### Create an Azure Resource group 
 [Follow the instructions here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal), if neccessary, to create your resource group.
### Create an Azure Storage account
Create a blob storage account in the resource group created in the previous step. [Follow the instructions here](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal), if necessary, to create your blob storage account. This will be used to restore the Wide World Importers database.
### Create an Azure SQL Server
1. In the Azure Portal, in **Create a resource**, choose **SQL Server** and click **Create.**
1. Choose your **Subscription**
1. Choose you **Resource group** you created in the previous step
1. Enter a **Server name** - note this must be unique across all azure
1. Choose your **location**
1. For authentication method, select **Use both SQL and Microsoft authentication**
1. Click the **Set admin** button and select your user account
1. Enter a **Server admin login and password**. Your screen should similar to the one below: ![create-sql-server1](images/create-sqlserver-1.jpg)
1. Navigate to the **Networking** tab and change the slider under Firewall rules to **Yes** to allow Azure services and resources to access this server.![create-sql-server2](images/create-sqlsserver-2.jpg)
1. Select **Review + create**
### Create an Azure SQL DB for Metadata Driven Pipeline Configurations
1. Go to the Azure SQL Server you created in the previous step and click **Create database**![sqldb1](images/create-sqldb-1.jpg)
1. Make sure your resource group and SQL server are selected. Enter **FabricMetadataOrchestration** for the database name.
1. For **Workload environment** Choose **Development**![sqldb2](images/create-sqldb-2.jpg)
1. Navigate to **Networking** and under **Firewall rules**, move slider for **Add current client IP address** to **Yes** ![sqldb3](images/create-sqldb-3.jpg)
1. Click **Review and create**
### Download and restore the Wide World Importers Database
1. Download the Wide World Importers Database for Azure SQL DB. [Click here to immediately download the bacpac](https://github.com/Microsoft/ql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac)
1. Upload the bacpac to the storage account created previously and restore the Wide World Importers database. [Follow the instructions here](https://learn.microsoft.com/en-us/azure/azure-sql/database/database-import?view=azuresql&tabs=azure-powershell), if necessary, to restore the database from the bacpac.
## Create Azure SQL DB Objects
Run scripts to create views, tables and stored procedures used in this tutorial.
### Create views in Wide World Importers database
1. Download the SQL script found in [in this repo](src/sql/1-wwi/create_source_views.sql).
1. Connect to the Wide World Importers Database in SQL Server Management Studio or Azure Data Studio
1. Run the script to script to create the views. You should see the following views as shown in Object Explorer below: ![wwiviews](images/metadata-tables-1.jpg)
### Create and load tables in the Metadata database
1. Download the SQL script found in [in this repo](src/sql/2-metadatadb/create-metadata-tables.sql)
1. Connect to the FabricMetadataOrchestration database in SQL Server Management Studio or Azure Data Studio
1. Run the script to script to create and load the tables. You should see the following tables as shown below: ![tables](images/metadata-tables-2.jpg)
Notice the values for the **loadtype**,**sqlsourcedatecolumn**,**sqlstartdate**, and **sqlenddate** columns of the **PipelineOrchestrator_FabricLakehouse** table. For the tables with **loadtype** equal to 'incremental', only 1 weeks worth of data will be loaded. This is because these tables are very large so for testing purposes, we only need a small amount of data. After these tables are loaded into the Lakehouse, the **sqlstartdate** will be updated to the max date of each column indicated in the **sqlsourcedatecolumn** for each table. This means that if you run the pipeline again without resetting the **sqlenddate**, no new data will be added to the tables that are incrementally loaded. You may be tempted to set the **sqlenddate** to NULL, which is what the value would be for scheduled loads in production, but I would caution you against doing that in this solution without testing how long the load from the World Wide Importers database to the Lakehouse runs. Instead, update the **sqlenddate** to add just a few more days worth of data after the inital run of just one week's data.

## Create Microsoft Fabric Resources
Create the Microsoft Fabric Workspace, Lakehouses, Data Warehouse, and Azure SQL DB Connections.
### Create a Microsoft Fabric workspace
[Create a Fabric Workspace](https://learn.microsoft.com/en-us/fabric/get-started/create-workspaces) in your Microsoft Fabric tenant
### Create Bronze and Gold Fabric Lakehouses
[Create 2 Microsoft Fabric Lakehouses](https://learn.microsoft.com/en-us/fabric/data-engineering/create-lakehouse) in you workspace.
After creating the Lakehouses, copy the lakehouse names and table URLs and keep for your reference. 
* To get the URLs, open each Lakehouse and click on the ellipses next to the **Tables** folder. Choose **Properties** and copy the abfss file path. ![getlakehouse](images/get_lakehouse_url.jpg)
* Paste each into notepad or a Word document and remove the "/Tables" from the end of the string. Your string will look something like **abfss://\<uniqueid>@onelake.dfs.fabric.microsoft.com/a\<anotheruniqueid>**
### Create a Fabric Data Warehouse
Create a Fabric Data Warehouse by [following the instructions here](https://learn.microsoft.com/en-us/fabric/data-warehouse/create-warehouse)
### Create Fabric Connections to your Azure SQL DBs
Create 2 Fabric connections, one to the Wide World Importers Azure SQL DB and to the FabricMetadataConfiguration Azure SQL DB [per the instructions here](https://learn.microsoft.com/en-us/fabric/data-factory/).
### Upload Spark Notebooks to Fabric
Upload the notebooks to be used in the pipeline
1. Download the 3 notebooks [found in the repo](src/notebooks/)
1. Log into the Microsoft Fabric portal and switch to the Data Science experience and click **Import notebook**![Import Notebook](images/datascience-import-1.jpg)
1. Select upload and choose all of the 3 notebooks to your Fabric Workspace. ![downloaded.](images/datascience-import-2.jpg)

## Create Microsoft Fabric Pipelines and Objects
From this point forward, the instructions will be an exercise of creating pipelines, adding activities and configuring the settings for each activity. The configurations for each activity are in a format that allows you to copy and paste values into each activity. It is important to copy the text exactly as is to avoid errors in scripts or subsequent activities. Do to the length of the instructions, I am keeping images in this post to a minimum - another reason to follow the instructions carefully. You can also refer to the original blog posts cited at the tops of this blog post for reference.
### Create the pipeline to load data from Wide World Importers to the Fabric Lakehouse
This pipeline loops through the tables defined in PipelineOrchestrator_FabricLakehouse table to load from World Wide Importers to the Fabric Lakehouse. The pipeline will look like this when finished: ![get-wwi-data](images/wwi-pipeline-complete.jpg)

1. Create a new Data Pipeline and call it "**Get WWImporters Data direct**"
1. Add a **Set variable** activity
1. Click on the canvas and add the following  pipeline **Parameters**:

      Name                | Type   |
     ------------------- | ------ |
     sqlsourcedatecolumn | String |
     sqlstartdate        | String |
     sqlenddate          | String |
     sqlsourceschema     | String |
     sqlsourcetable      | String |
     sinktablename       | String |
     loadtype            | String |
     sourcekeycolumn     | String |
     batchloaddatetime   | String |
1. Move to the **Variables** tab and add the following variables: 

    | Name              | Type   |
    | ----------------- | ------ |
    | datepredicate     | String |
    | maxdate           | String |
    | rowsinserted      | String |
    | rowsupdated       | String |
    | pipelinestarttime | String |
    | pipelineendtime   | String |
1. Configure the **Set variable** activity created in the 2nd step:

    | Tab      | Configuration | Value Type         | Value                 |
    | -------- | ------------- | ------------------ | --------------------- |
    | General  | Name          | String             | Set pipelinestarttime |
    | Settings | Variable type | Radio Button       | Pipeline variable     |
    | Settings | Name          | String             | pipelinestarttime     |
    | Settings | Value         | Dynamic Expression | @utcnow()             |
1. Add another **Set variable**, drag the green arrow from the previous activity to it and configure:

    | Tab      | Configuration | Value Type   | Value              |
    | -------- | ------------- | ------------ | ------------------ |
    | General  | Name          | String       | Set Date predicate |
    | Settings | Variable type | Radio Button | Pipeline variable  |
    | Settings | Name          | String       | datepredicate      |
    | Settings | Value         | Dynamic Expression |@if(equals(pipeline().parameters.sqlenddate,null),concat(pipeline().parameters.sqlsourcedatecolumn,' >= ''', pipeline().parameters.sqlstartdate,''''),concat(pipeline().parameters.sqlsourcedatecolumn, ' >= ''',pipeline().parameters.sqlstartdate,''' and ', pipeline().parameters.sqlsourcedatecolumn,' < ''',pipeline().parameters.sqlenddate,'''')) |
1. Add **If condition** activity, drag arrow from previous activity and configure:
    | Tab        | Configuration | Value Type         | Value                                          |
    | ---------- | ------------- | ------------------ | ---------------------------------------------- |
    | General    | Name          | String             | Check loadtype                                 |
    | Activities | Expression    | Dynamic Expression | @equals(pipeline().parameters.loadtype,'full') |
1. Now configure the **If True** activities. Your True activities will be a flow of activities when the table to be loaded should be a full load. When completed, the True activities will look like this: ![full-load](images/wwi-fullload-activities.jpg)
    1. Add **Copy Data** activity and configure:
        | Tab     | Configuration   | Value Type   | Value                           |
        | ------- | --------------- | ------------ | ------------------------------- |
        | General | Name            | String       | Copy data to delta table        |
        | Source  | Data store type | Radio button | External                        |
        | Source  | Connection      | Drop down    | \<choose your metadata database> |
        | Source  | Connection type | Drop down    | Azure SQL Database              |
        | Source  | User query      | Radio button | Query                           |
        | Source  | Query           | Dynamic Expression | select * from @{pipeline().parameters.sqlsourceschema}.@{pipeline().parameters.sqlsourcetable} where  @{variables('datepredicate')} |
        | Destination | Data store type           | Radio button       | Workspace                            |
        | Destination | Workspace data store type | Drop down          | Lakehouse                            |
        | Destination | Lakehouse                 | Drop down          | \<choose your lakehouse>              |
        | Destination | Root folder               | Radio button       | Tables                               |
        | Destination | Table name                | Dynamic Expression | @pipeline().parameters.sinktablename |
        | Destination | Advanced-> Table action   | Radio button       | Overwrite                            |
    1. Add **Notebook** activity, drag arrow from previous activity and configure:
        | Tab      | Configuration               | Add New Parameter | Value Type         | Value                                      |
        | -------- | --------------------------- | ----------------- | ------------------ | ------------------------------------------ |
        | General  | Settings                    |                   | String             | Get MaxDate loaded                         |
        | Settings | Notebook                    |                   | Dropdown           | Get Max Data from Delta Table              |
        | Settings | Advanced -> Base parameters | lakehousePath     | String             | \<your Bronze lakehouse abfs path>          |
        | Settings | Advanced -> Base parameters | tableName         | Dynamic Expression | @pipeline().parameters.sinktablename       |
        | Settings | Advanced -> Base parameters | tableKey          | Dynamic Expression | @pipeline().parameters.sourcekeycolumn     |
        | Settings | Advanced -> Base parameters | dateColumn        | Dynamic Expression | @pipeline().parameters.sqlsourcedatecolumn |
    1. Add **Set variable**, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                                                                               |
        | -------- | ------------- | ------------------ | ----------------------------------------------------------------------------------- |
        | General  | Name          | String             | Get maxdate                                                                         |
        | Settings | Variable type | Radio Button       | Pipeline variable                                                                   |
        | Settings | Name          | Dropdown           | maxdate                                                                             |
        | Settings | Value         | Dynamic Expression | @split(split(activity('Get MaxDate loaded').output.result.exitValue,'\|')[0],'=')[1] |
    1. Add another **Set variable**, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type   | Value             |
        | -------- | ------------- | ------------ | ----------------- |
        | General  | Name          | String       | set rows inserted |
        | Settings | Variable type | Radio Button | Pipeline variable |
        | Settings | Name          | Dropdown     | rowsinserted      |
        | Settings | Value         | Dynamic Expression | @split(split(activity('Get MaxDate loaded').output.result.exitValue,'\|')[1],'=')[1] |
    1. Add another **Set variable**, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                |
        | -------- | ------------- | ------------------ | -------------------- |
        | General  | Name          | String             | Set pipeline endtime |
        | Settings | Variable type | Radio Button       | Pipeline variable    |
        | Settings | Name          | Dropdown           | pipelineendtime      |
        | Settings | Value         | Dynamic Expression | @utcnow()            |
    1. Add  **Script**, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration   | Value Type   | Value                           |
        | -------- | --------------- | ------------ | ------------------------------- |
        | General  | Name            | String       | Update Pipeline Run details     |
        | Settings | Data store type | Radio Button | External                        |
        | Settings | Connection      | Dropdown     | <choose your metadata database> |
        | Settings | Script          | Radio Button | NonQuery                        |
        | Settings | Script          | Dynamic Expression  | Update dbo.PipelineOrchestrator_FabricLakehouse set batchloaddatetime = '@{pipeline().parameters.batchloaddatetime}', loadstatus = '@{activity('Copy data to delta table').output.executionDetails[0].status}', rowsread = @{activity('Copy data to delta table').output.rowsRead}, rowscopied= @{activity('Copy data to delta table').output.rowsCopied}, deltalakeinserted = '@{variables('rowsinserted')}', deltalakeupdated =0, sqlmaxdatetime = '@{variables('maxdate')}', pipelinestarttime='@{variables('pipelinestarttime')}', pipelineendtime = '@{variables('pipelineendtime')}' where sqlsourceschema = '@{pipeline().parameters.sqlsourceschema}' and sqlsourcetable = '@{pipeline().parameters.sqlsourcetable}' |
    1. Exit the **True activities** box of the **If condition** by clicking on  **Main canvas** in the upper left corner
1. Now configure the **If False** activities. Your False activities will be a flow of activities when the table to be loaded should be an incremental load. When completed, the False activities will look like this: ![wwi-incremental](images/wwi-incremental-activities.jpg)
    1. Add **Copy Data** activity:
        | Tab     | Configuration   | Value Type   | Value                           |
        | ------- | --------------- | ------------ | ------------------------------- |
        | General | Name            | String       | Copy data to parquet            |
        | Source  | Data store type | Radio button | External                        |
        | Source  | Connection      | Drop down    | <choose your metadata database> |
        | Source  | Connection type | Drop down    | Azure SQL Database              |
        | Source  | User query      | Radio button | Query                           |
        | Source  | Query      | Dynamic Expression | select * from @{pipeline().parameters.sqlsourceschema}.@{pipeline().parameters.sqlsourcetable} where  @{variables('datepredicate')} |
        | Destination | Data store type           | Radio button | Workspace               |
        | Destination | Workspace data store type | Drop down    | Lakehouse               |
        | Destination | Lakehouse                 | Drop down    | <choose your lakehouse> |
        | Destination | Root folder               | Radio button | Files                   |
        | Destination  | File Path (1)  | Dynamic Expression | incremental/@{pipeline().parameters.sinktablename} |
        | Destination  | File Path (2)  | Dynamic Expression | @{pipeline().parameters.sinktablename}.parquet |
        | Destination  | File format      | Drop down | Parquet |
    1. Add **Notebook** activity, drag the green arrow from previous activity and configure:
        | Tab      | Configuration               | Add New Parameter | Value Type         | Value                                      |
        | -------- | --------------------------- | ----------------- | ------------------ | ------------------------------------------ |
        | General  | Settings                    |                   | String             | Load to Delta                              |
        | Settings | Notebook                    |                   | Dropdown           | Create or Merge to Deltalake               |
        | Settings | Advanced -> Base parameters | lakehousePath     | String             | \<your Bronze lakehouse abfs path>          |
        | Settings | Advanced -> Base parameters | tableName         | Dynamic Expression | @pipeline().parameters.sinktablename       |
        | Settings | Advanced -> Base parameters | tableKey          | Dynamic Expression | @pipeline().parameters.sourcekeycolumn     |
        | Settings | Advanced -> Base parameters | dateColumn        | Dynamic Expression | @pipeline().parameters.sqlsourcedatecolumn |
    1. Add **Set variable**, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                                                                          |
        | -------- | ------------- | ------------------ | ------------------------------------------------------------------------------ |
        | General  | Name          | String             | Get maxdate incr                                                               |
        | Settings | Variable type | Radio Button       | Pipeline variable                                                              |
        | Settings | Name          | Dropdown           | maxdate                                                                        |
        | Settings | Value         | Dynamic Expression | @split(split(activity('Load to Delta').output.result.exitValue,'\|')[0],'=')[1] |
    1. Add **Set variable**, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                                                                          |
        | -------- | ------------- | ------------------ | ------------------------------------------------------------------------------ |
        | General  | Name          | String             | set rows inserted incr                                                         |
        | Settings | Variable type | Radio Button       | Pipeline variable                                                              |
        | Settings | Name          | Dropdown           | rowsinserted                                                                   |
        | Settings | Value         | Dynamic Expression | @split(split(activity('Load to Delta').output.result.exitValue,'\|')[1],'=')[1] |
    1. Add **Set variable**, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                                                                          |
        | -------- | ------------- | ------------------ | ------------------------------------------------------------------------------ |
        | General  | Name          | String             | set rows updated incr                                                          |
        | Settings | Variable type | Radio Button       | Pipeline variable                                                              |
        | Settings | Name          | Dropdown           | rowsupdated                                                                    |
        | Settings | Value         | Dynamic Expression | @split(split(activity('Load to Delta').output.result.exitValue,'\|')[2],'=')[1] |
    1. Add **Set variable**, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                     |
        | -------- | ------------- | ------------------ | ------------------------- |
        | General  | Name          | String             | Set pipeline endtime incr |
        | Settings | Variable type | Radio Button       | Pipeline variable         |
        | Settings | Name          | Dropdown           | pipelineendtime           |
        | Settings | Value         | Dynamic Expression | @utcnow()                 |
    1. Add  **Script**, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration   | Value Type   | Value                                             |
        | -------- | --------------- | ------------ | ------------------------------------------------- |
        | General  | Name            | String       | Update Pipeline Run details - incremental         |
        | Settings | Data store type | Radio Button | External                                          |
        | Settings | Connection      | Dropdown     | Connection to FabricMetdataOrchestration Database |
        | Settings | Script(1)       | Radio Button | NonQuery                                          |
        | Settings | Script(2)       | Dynamic Expression | Update dbo.PipelineOrchestrator_FabricLakehouse set batchloaddatetime = '@{pipeline().parameters.batchloaddatetime}', loadstatus = '@{activity('Copy data to parquet').output.executionDetails[0].status}', rowsread = @{activity('Copy data to parquet').output.rowsRead}, rowscopied= @{activity('Copy data to parquet').output.rowsCopied},deltalakeinserted = '@{variables('rowsinserted')}',deltalakeupdated = '@{variables('rowsupdated')}', sqlmaxdatetime = '@{variables('maxdate')}', sqlstartdate = '@{variables('maxdate')}', pipelinestarttime='@{variables('pipelinestarttime')}', pipelineendtime = '@{variables('pipelineendtime')}'  where sqlsourceschema = '@{pipeline().parameters.sqlsourceschema}' and sqlsourcetable = '@{pipeline().parameters.sqlsourcetable}' |
    1. Exit the **False activities** box of the **If condition** by clicking on  **Main canvas** in the upper left corner
If you have gotten this far, awesome! Thank you! Save your changes! You are done with your first pipeline!

To actually run the pipeline, we will start building our Orchestrator pipeline. An Orchestrator pipeline is the main pipeline that links together large flows of activities.
### Configure the Orchestrator Pipeline Part 1 - Invoke Pipeline to load from World Wide Importers to Fabric Lakehouse
We will now start building the Orchestrator pipeline which will kickoff the pipeline to create or load each table from the World Wide Importers Database to the Fabric Lakehouse. When you are finished with Part 1, your Orchestrator Pipeline will look like this: ![orchestrator-1](images/orchestrator-1.jpg)
1. Create a new Data Pipeline called **orchestrator Load WWI to Fabric**
1. Add a **Set Variable** activity
1. Click on the canvas and create the following **Parameters**:
   | Name       | Type | Default Value | Description                                             |
   | ---------- | ---- | ------------- | ------------------------------------------------------- |
   | startyear  | int  | 2013          | Year to start loading from WWI                          |
   | endyear    | int  | 2025          | Year to end loading from WWI                            |
   | loaddwh    | int  | 0             | Set to 1 if you want to load to Fabric Data Warehouse   |
   | loadgoldlh | int  | 1             | Set to 1 if you want to load to Fabric Gold Lakehouse   |
   | loadbronze | int  | 1             | Set to 1 if you want to load to Fabric Bronze Lakehouse |
   | waittime | int  | 300            | Delay needed for tables to materialize in Bronze Lakehouse before loading to DW or Gold LH. Can set to 1 if not loading Bronze or only loading to Bronze |
1. Add pipeline **Variables**
   | Name              | Type   |
   | ----------------- | ------ |
   | batchloaddatetime | String |
1. Go back to the **Set variable** activity you added in step 2 and configure:
   | Tab      | Configuration | Value Type         | Value                   |
   | -------- | ------------- | ------------------ | ----------------------- |
   | General  | Name          | String             | set batch load datetime |
   | Settings | Variable type | Radio Button       | Pipeline variable       |
   | Settings | Name          | Dropdown           | batchloaddatetime       |
   | Settings | Value         | Dynamic Expression | @pipeline().TriggerTime |
1. Add **Lookup** activity, drag the green arrow from the previous activity to it and configure:
   | Tab      | Configuration   | Value Type   | Value                                |
   | -------- | --------------- | ------------ | ------------------------------------ |
   | General  | Name            | String       | Get tables to load to deltalake      |
   | Settings | Data store type | Radio button | External                             |
   | Settings | Connection      | Drop down    | Connection to your metadata database |
   | Settings | Connection Type | Drop down    | Azure SQL Database                   |
   | Settings | Use query       | Radio button | Query                                |
   | Settings |  | Drop down    | Azure SQL Database                   |
   | Settings | Use query       | Radio button | Query                                |
   | Settings | Query       | Dynamic Expression |select * from dbo.PipelineOrchestrator_FabricLakehouse where skipload=0 and 1=@{pipeline().parameters.loadbronze} |
   | Settings | First row only      | Check box | Not Checked                                |
1. Add **For each** activity, drag the green arrow from the previous activity to it and configure:
   | Tab        | Configuration | Value Type                                    | Value                                                     |
   | ---------- | ------------- | --------------------------------------------- | --------------------------------------------------------- |
   | General    | Name          | String                                        | For each table to load to deltalake                       |
   | Settings   | Batch count   | String                                        | 4                                                         |
   | Settings   | Items         | Dynamic Expression                            | @activity('Get tables to load to deltalake').output.value |
                                                        |
1. Click on the pencil in the **Activities** box of the **For Each** and add an **Invoke Pipeline** activity and configure as follows:
   | Tab      | Configuration      | Parameter Name      | Value Type         | Value                           |
   | -------- | ------------------ | ------------------- | ------------------ | ------------------------------- |
   | General  | Name               |                     | String             | Get WWImporters Data            |
   | Settings | Invoked pipeline   |                     | Dropdown           | Get WWI Importers Data direct   |
   | Settings | Wait on completion |                     | Checkbox           | Checked                         |
   | Settings | Parameters         | sqlsourcedatecolumn | Dynamic Expression | @item().sqlsourcedatecolumn     |
   | Settings | Parameters         | sqlstartdate        | Dynamic Expression | @item().sqlstartdate            |
   | Settings | Parameters         | sqlenddate          | Dynamic Expression | @item().sqlenddate              |
   | Settings | Parameters         | sqlsourceschema     | Dynamic Expression | @item().sqlsourceschema         |
   | Settings | Parameters         | sqlsourcetable      | Dynamic Expression | @item().sqlsourcetable          |
   | Settings | Parameters         | sinktablename       | Dynamic Expression | @item().sinktablename           |
   | Settings | Parameters         | loadtype            | Dynamic Expression | @item().loadtype                |
   | Settings | Parameters         | sourcekeycolumn     | Dynamic Expression | @item().sourcekeycolumn         |
   | Settings | Parameters         | batchloaddatetime   | Dynamic Expression | @variables('batchloaddatetime') |
1. Exit the **Activities** box in the For each activity by clicking on  **Main canvas** in the upper left corner
1. On the Main Canvas, add **Notebook** activity, drag the green arrow from the **For each** activity to it and configure:
   | Tab      | Configuration   | Add New Parameter | Parameter Type | Value Type         | Value                            |
   | -------- | --------------- | ----------------- | -------------- | ------------------ | -------------------------------- |
   | General  | Name            |                   |                | String             | Build Calendar                   |
   | Settings | Notebook        |                   |                | Dropdown           | Build Calendar                   |
   | Settings | Base parameters | startyear         | int            | Dynamic Expression | @pipeline().parameters.startyear |
   | Settings | Base parameters | endyear           | int            | Dynamic Expression | @pipeline().parameters.endyear   |

Run the Orchestrator pipeline to load the Lakehouse. When it is complete, you should see the following tables and files in your Lakehouse: ![lakehouse-tables1](images/lakehouse-tables-1.jpg)

Now that we have the tables in our Fabric Lakehouse, we can create SQL views over them which will be used to load our Fabric Gold Lakehouse and/or our Fabric Data Warehouse.
### Create Data Warehouse Objects
If you read the blog posts, you would have read that at this point in time the Lakehouse SQL Endpoint is not exposed in the Copy Data pipeline activity. So while you can build SQL views in the Lakehouse, you can not leverage them in a Copy Data activity. Therefore, we will create the SQL Views in the Fabric Data Warehouse.
1. Download the Datawarehouse SQL script file [located here](src/fabricdw/create-fabric-dw-objects.sql).
1. Open the downloaded SQL script (create-fabric-dw-objects.sql) using notepad and copy the entire contents of the script.
1. From the Fabric portal, go to you Fabric Workspace and open your Data Warehouse and 
[create a new Query](https://learn.microsoft.com/en-us/fabric/data-warehouse/query-warehouse).
1. Paste the code into the Fabric Data Warehouse query.
1. Do a Find and Replace **[Ctrl-H]** and replace the text **myFTAFabricWarehouse** with your Fabric Warehouse name.
1. Do another Find and Replace and replace the text **myFTAFabricLakehouse** with your Fabric Lakehouse name.
1. Run the SQL query script. You should see the following objects in you Fabric Data Warehouse after running the script: ![dw-objects](images/dw-objects.jpg)

Now that we have the views needed to load both the Lakehouse and Warehouse as well as the tables and stored procedure for the Warehouse, we can continue with building our data pipelines.
### Create the pipeline to load data from Fabric Lakehouse to Gold Fabric Lakehouse
When this pipeline is complete, it will look like this: ![lakehousetable](images/load-lakehouse-pipeline.jpg)

1. Create a new Data Pipeline called **Load Lakehouse Table**
1. Add a **Set Variable** activity
1. Click on the canvas and create the following **Parameters**:
    | Name              | Type   |
    | ----------------- | ------ |
    | sourcestartdate   | String |
    | sourcestartdate   | String |
    | sourceenddate     | String |
    | sourceschema      | String |
    | sourcetable       | String |
    | loadtype          | String |
    | batchloaddatetime | String |
    | sinktable         | String |
    | tablekey          | String |
    | tablekey2         | String |
1. Add pipeline **Variables**:
    | Name              | Type   |
    | ----------------- | ------ |
    | datepredicate     | String |
    | maxdate           | String |
    | rowsinserted      | String |
    | rowsupdated       | String |
    | pipelinestarttime | String |
    | pipelineendtime   | String |
1. Configure the **Set variable** added in step 2:
     Tab      | Configuration | Value type         | Value                 |
    | -------- | ------------- | ------------------ | --------------------- |
    | General  | Name          | String             | Set pipelinestarttime |
    | Settings | Variable type | Radio Button       | Pipeline variable     |
    | Settings | Name          | String             | pipelinestarttime     |
    | Settings | Value         | Dynamic Expression | @utcnow()             |
1. Add **If condition** activity, drag the green arrow from the previous activity to it and configure:
    | Tab        | Configuration | Value type         | Value                                          |
    | ---------- | ------------- | ------------------ | ---------------------------------------------- |
    | General    | Name          | String             | Check loadtype                                 |
    | Activities | Expression    | Dynamic Expression | @equals(pipeline().parameters.loadtype,'full') |
1. Now configure the **If True** activities. Like the previous pipeline, the True activities will be a flow of activities when the table to be loaded should be a full load. When completed, the True activities will look like this:![lakehouse-true](images/load-lakehouse-full.jpg)

    1. Add **Copy Data** Activity and configure:
    
        | Tab         | Configuration             | Value Type         | Value                               |
        | ----------- | ------------------------- | ------------------ | ----------------------------------- |
        | General     | Name                      | String             | Copy data to gold lakehouse         |
        | Source      | Data store type           | Radio Button       | Workspace                           |
        | Source      | Workspace data store type | Drop down          | Data Warehouse                      |
        | Source      | Data Warehouse            | Drop down          | \<your Data Warehouse name>                     |
        | Source      | Use query                 | Radio Button       | Table                               |
        | Source      | Table (Schema)            | Dynamic Expression | @pipeline().parameters.sourceschema |
        | Source      | Table (Table name)        | Dynamic Expression | @pipeline().parameters.sourcetable  |
        | Destination | Data store type           | Radio Button       | Workspace                           |
        | Destination | Workspace data store type | Drop down          | Lakehouse                           |
        | Destination | Lakehouse                 | Drop down          | \<your Gold Lakehouse name>          |
        | Destination | Root folder               | Radio Button       | Tables                              |
        | Destination | Table (Table name)        | Dynamic Expression | @pipeline().parameters.sinktable    |
        | Destination | Advanced -> Table action  | Radio Button       | Overwrite                           |
    1. Add **Set variable** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                |
        | -------- | ------------- | ------------------ | -------------------- |
        | General  | Name          | String             | Set pipeline endtime |
        | Settings | Variable type | Radio Button       | Pipeline variable    |
        | Settings | Name          | Dropdown           | pipelineendtime      |
        | Settings | Value         | Dynamic Expression | @utcnow()            |
    1. Add **Script** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration   | Value Type   | Value                                             |
        | -------- | --------------- | ------------ | ------------------------------------------------- |
        | General  | Name            | String       | Update Pipeline Run details                       |
        | Settings | Data store type | Radio Button | External                                          |
        | Settings | Connection      | Dropdown     | Connection to FabricMetdataOrchestration Database |
        | Settings | Script(1)       | Radio Button | NonQuery                                          |
        | Settings | Script(2)       | Dynamic Expression | Update dbo.PipelineOrchestrator_FabricLakehouseGold set batchloaddatetime = '@{pipeline().parameters.batchloaddatetime}', loadstatus = '@{activity('Copy data to gold lakehouse').output.executionDetails[0].status}',  rowscopied= @{activity('Copy data to gold lakehouse').output.rowsCopied},deltalakeinserted= @{activity('Copy data to gold lakehouse').output.rowsCopied}, rowsread= @{activity('Copy data to gold lakehouse').output.rowsRead}, pipelinestarttime='@{variables('pipelinestarttime')}', pipelineendtime = '@{variables('pipelineendtime')}' where sourceschema = '@{pipeline().parameters.sourceschema}' and sourcetable = '@{pipeline().parameters.sourcetable}'  |
    1. Exit the **True activities** box of the **If condition** by clicking on  **Main canvas** in the upper left corner
1. Now configure the **If False** activities. Your False activities will be a flow of activities when the table to be loaded should be an incremental load. When completed, the False activities will look like this: ![table-l=incremental](images/load-lakehouse-incr.jpg)

    1. Add **Set variable** activity and configure:
        | Tab      | Configuration | Value Type   | Value              |
        | -------- | ------------- | ------------ | ------------------ |
        | General  | Name          | String       | Set date predicate |
        | Settings | Variable type | Radio Button | Pipeline variable  |
        | Settings | Name          | String       | datepredicate      |
        | Settings | Value          |Dynamic Expression     | @if(equals(pipeline().parameters.sourceenddate,null),concat('LastUpdated >= ''', pipeline().parameters.sourcestartdate,''''),concat('LastUpdated >= ''',pipeline().parameters.sourcestartdate,''' and LastUpdated < ''',pipeline().parameters.sourceenddate,''''))    |
    1. Add **Copy Data** activity, drag the green arrow from the previous activity to it and configure:
        | Tab     | Configuration             | Value Type   | Value                          |
        | ------- | ------------------------- | ------------ | ------------------------------ |
        | General | Name                      | String       | Get incremental fact data      |
        | Source  | Data store type           | Radio button | Workspace                      |
        | Source  | Workspace data store type | Drop down    | Data Warehouse                 |
        | Source  | Data Warehouse            | Drop down    | \<choose your Fabric Warehouse> |
        | Source  | Use query                 | Radio button | Query                          |
        | Source  | Query               | Dynamic Expression | select * from @{pipeline().parameters.sourceschema}.@{pipeline().parameters.sourcetable} where @{variables('datepredicate')} |
        | Destination | Data store type           | Radio button       | Workspace                                      |
        | Destination | Workspace data store type | Drop down          | Lakehouse                                      |
        | Destination | Lakehouse                 | Drop down          | \<choose your Gold lakehouse>                   |
        | Destination | Root folder               | Radio button       | Files                                          |
        | Destination | File Path (1)             | Dynamic Expression | incremental/@{pipeline().parameters.sinktable} |
        | Destination | File Path (2)             | Dynamic Expression | @{pipeline().parameters.sinktable}.parquet     |
        | Destination | File format               | Drop down          | Parquet                                        |
    1. Add **Notebook** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration               | Add New Parameter | Value Type         | Value                            |
        | -------- | --------------------------- | ----------------- | ------------------ | -------------------------------- |
        | General  | Settings                    |                   | String             | Merge to Gold                    |
        | Settings | Notebook                    |                   | Dropdown           | Create or Merge to Deltalake     |
        | Settings | Advanced -> Base parameters | lakehousePath     | String             | \<your Gold lakehouse abfs path>  |
        | Settings | Advanced -> Base parameters | tableName         | Dynamic Expression | @pipeline().parameters.sinktable |
        | Settings | Advanced -> Base parameters | tableKey          | Dynamic Expression | @pipeline().parameters.tablekey  |
        | Settings | Advanced -> Base parameters | tableKey2         | Dynamic Expression | @pipeline().parameters.tablekey2 |
        | Settings | Advanced -> Base parameters | dateColumn        | String             | LastUpdated                      |
    1. Add **Set variable** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                                                                          |
        | -------- | ------------- | ------------------ | ------------------------------------------------------------------------------ |
        | General  | Name          | String             | Get maxdate incr                                                               |
        | Settings | Variable type | Radio Button       | Pipeline variable                                                              |
        | Settings | Name          | Dropdown           | maxdate                                                                        |
        | Settings | Value         | Dynamic Expression | @split(split(activity('Load to Delta').output.result.exitValue,'\|')[0],'=')[1] |
    1. Add **Set variable** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                                                                          |
        | -------- | ------------- | ------------------ | ------------------------------------------------------------------------------ |
        | General  | Name          | String             | set rows inserted incr                                                         |
        | Settings | Variable type | Radio Button       | Pipeline variable                                                              |
        | Settings | Name          | Dropdown           | rowsinserted                                                                   |
        | Settings | Value         | Dynamic Expression | @split(split(activity('Load to Delta').output.result.exitValue,'\|')[1],'=')[1] |
    1. Add **Set variable** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                                                                          |
        | -------- | ------------- | ------------------ | ------------------------------------------------------------------------------ |
        | General  | Name          | String             | set rows updated incr                                                          |
        | Settings | Variable type | Radio Button       | Pipeline variable                                                              |
        | Settings | Name          | Dropdown           | rowsupdated                                                                    |
        | Settings | Value         | Dynamic Expression | @split(split(activity('Load to Delta').output.result.exitValue,'\|')[2],'=')[1] |
    1. Add **Set variable** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                     |
        | -------- | ------------- | ------------------ | ------------------------- |
        | General  | Name          | String             | Set pipeline endtime incr |
        | Settings | Variable type | Radio Button       | Pipeline variable         |
        | Settings | Name          | Dropdown           | pipelineendtime           |
        | Settings | Value         | Dynamic Expression | @utcnow()                 |
    1. Add **Script** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration   | Value Type   | Value                                             |
        | -------- | --------------- | ------------ | ------------------------------------------------- |
        | General  | Name            | String       | Update Pipeline Run details - incremental         |
        | Settings | Data store type | Radio Button | External                                          |
        | Settings | Connection      | Dropdown     | Connection to FabricMetdataOrchestration Database |
        | Settings | Script(1)       | Radio Button | NonQuery                                          |
        | Settings | Script(1)       | Dynamic Expression | Update dbo.PipelineOrchestrator_FabricLakehouse set batchloaddatetime = '@{pipeline().parameters.batchloaddatetime}', loadstatus = '@{activity('Copy data to parquet').output.executionDetails[0].status}', rowsread = @{activity('Copy data to parquet').output.rowsRead}, rowscopied= @{activity('Copy data to parquet').output.rowsCopied},deltalakeinserted = '@{variables('rowsinserted')}',deltalakeupdated = '@{variables('rowsupdated')}', sqlmaxdatetime = '@{variables('maxdate')}', sqlstartdate = '@{variables('maxdate')}', pipelinestarttime='@{variables('pipelinestarttime')}', pipelineendtime = '@{variables('pipelineendtime')}'  where sqlsourceschema = '@{pipeline().parameters.sqlsourceschema}' and sqlsourcetable = '@{pipeline().parameters.sqlsourcetable}' |
    1. Exit the **False activities** box of the **If condition** by clicking on  **Main canvas** in the upper left corner

You are done with this pipeline! Save your changes!
### Configure the Orchestrator Pipeline Part 2 - Invoke Pipeline to load from Fabric Lakehouse to Gold Lakehouse
Now we will update the Orchestrator pipeline, **orchestrator Load WWI to Fabric**, to load data from the first Fabric Lakehouse to the Gold Fabric Lakehouse. When you are done, your pipeline should look like this: ![orchestrator-part2](images/orchestrator-2.jpg)

1. It can take up to 5 minutes from the time a table is created in the Fabric Lakehouse for it to be available in an endpoint. So we'll add a **Wait** activity. Drag the green arrow from the Build Calendar **Notebook** activity to it and configure:
    | Tab      | Configuration        | Value Type         | Value                           |
    | -------- | -------------------- | ------------------ | ------------------------------- |
    | General  | Name                 | String             | Delay gold load                 |
    | Settings | Wait time in seconds | Dynamic Expression | @pipeline().parameters.waittime |
1. Add **Lookup** activity, drag the green arrow from the previous activity to it and configure:
    | Tab      | Configuration   | Value Type         | Value                                                                                                                    |
    | -------- | --------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------ |
    | General  | Name            | String             | Get tables to load to gold lakehouse                                                                                     |
    | Settings | Data store type | Radio button       | External                                                                                                                 |
    | Settings | Connection      | Drop down          | Connection to your metadata database                                                                                     |
    | Settings | Connection Type | Drop down          | Azure SQL Database                                                                                                       |
    | Settings | Use query       | Radio button       | Query                                                                                                                    |
    | Settings | Query           | Dynamic Expression | select \* from dbo.PipelineOrchestrator_FabricLakehouseGold where skipload=0 and @{pipeline().parameters.loadgoldlh} = 1 |
    | Settings | First row only  | Check box          | Not Checked                                                                                                              |
1. Add **For each** activity, drag the green arrow from the previous activity to it and configure:
    | Tab        | Configuration | Value Type                                    | Value                                                          |
    | ---------- | ------------- | --------------------------------------------- | -------------------------------------------------------------- |
    | General    | Name          | String                                        | For each table to load to gold lakehouse                       |
    | Settings   | Items         | Dynamic Expression                            | @activity('Get tables to load to gold lakehouse').output.value |
1. Click on the pencil in the **Activities** box of the **For Each** and add an **Invoke Pipeline** activity and configure as follows:
    | Tab      | Configuration      | Parameter Name    | Value Type         | Value                           |
    | -------- | ------------------ | ----------------- | ------------------ | ------------------------------- |
    | General  | Name               |                   | String             | Invoke Load Gold Lakehouse      |
    | Settings | Invoked pipeline   |                   | Dropdown           | Load Lakehouse Table            |
    | Settings | Wait on completion |                   | Checkbox           | Checked                         |
    | Settings | Parameters         | sourcestartdate   | Dynamic Expression | @item().sourcestartdate         |
    | Settings | Parameters         | sourceenddate     | Dynamic Expression | @item().sourceenddate           |
    | Settings | Parameters         | sourceschema      | Dynamic Expression | @item().sourceschema            |
    | Settings | Parameters         | sourcetable       | Dynamic Expression | @item().sourcetable             |
    | Settings | Parameters         | loadtype          | Dynamic Expression | @item().loadtype                |
    | Settings | Parameters         | batchloaddatetime | Dynamic Expression | @variables('batchloaddatetime') |
    | Settings | Parameters         | sinktable         | Dynamic Expression | @item().sinktable               |
    | Settings | Parameters         | tablekey          | Dynamic Expression | @item().tablekey                |
    | Settings | Parameters         | Tablekey2         | Dynamic Expression | @item().tablekey2               |
1. Exit the **Activities** box in the **For each** activity by clicking on  **Main canvas** in the upper left corner
1. Save the Orchestrator Pipeline and Run it. If you just loaded the first Lakehouse, you can run the Orchestrator Pipeline but set the parameters to run only the Lakehouse to Gold Lakehouse load: ![run-gold](images/run-gold-only.jpg)
When your pipeline has finished, you should now have these tables and files in your Gold Lakehouse: ![gold-lh](images/goldlh-tables.jpg)

And now you can be done if you want! But why not explore the functionality of a Fabric Data Warehouse?!?! Let's add one more pipeline to do that.
### Create the pipeline to load data from Fabric Lakehouse to Gold Data Warehouse
When this pipeline is complete, it will look like this: ![gold-dw-tables](images/golddw-tables.jpg)
1. Create a new Data Pipeline called **Load Warehouse Table**
1. Add a **Set Variable** activity
1. Click on the canvas and create the following **Parameters**:
    | Name              | Type   |
    | ----------------- | ------ |
    | sourcestartdate   | String |
    | sourcestartdate   | String |
    | sourceenddate     | String |
    | sourceschema      | String |
    | sourcetable       | String |
    | sinkschema        | String |
    | loadtype          | String |
    | batchloaddatetime | String |
    | sinktable         | String |
    | storedprocschema  | String |
    | storedprocname    | String |
1. Add the following pipeline **Variables**:
    | Name              | Type   |
    | ----------------- | ------ |
    | pipelinestarttime | String |
    | pipelineendtime   | String |
1. Configure the **Set variable** activity created in step 2:
    | Tab      | Configuration | Value type         | Value                 |
    | -------- | ------------- | ------------------ | --------------------- |
    | General  | Name          | String             | Set pipelinestarttime |
    | Settings | Variable type | Radio Button       | Pipeline variable     |
    | Settings | Name          | String             | pipelinestarttime     |
    | Settings | Value         | Dynamic Expression | @utcnow()             |
1. Add **If condition** activity, drag the green arrow from the previous activity to it and configure:
    | Tab        | Configuration | Value type         | Value                                          |
    | ---------- | ------------- | ------------------ | ---------------------------------------------- |
    | General    | Name          | String             | Check loadtype                                 |
    | Activities | Expression    | Dynamic Expression | @equals(pipeline().parameters.loadtype,'full') |
1. Now configure the **If True** activities. Like the previous pipelines, the True activities will be a flow of activities when the table to be loaded should be a full load. When completed, the True activities will look like this:![dw-true](images/dw-full.jpg)
    1. Add **Copy Data** activity and configure:
        | Tab         | Configuration               | Value Type         | Value                                                                              |
        | ----------- | --------------------------- | ------------------ | ---------------------------------------------------------------------------------- |
        | General     | Name                        | String             | Copy data to warehouse                                                             |
        | Source      | Data store type             | Radio Button       | Workspace                                                                          |
        | Source      | Workspace data store type   | Drop down          | Data Warehouse                                                                     |
        | Source      | Data Warehouse              | Drop down          | \<your DWH name>                                                                    |
        | Source      | Use query                   | Radio Button       | Table                                                                              |
        | Source      | Table (Schema)              | Dynamic Expression | @pipeline().parameters.sourceschema                                                |
        | Source      | Table (Table name)          | Dynamic Expression | @pipeline().parameters.sourcetable                                                 |
        | Destination | Data store type             | Radio Button       | Workspace                                                                          |
        | Destination | Workspace data store type   | Drop down          | Dara Warehouse                                                                     |
        | Destination | Data Warehouse              | Drop down          | \<your Fabric Data Warehouse name>                                                  |
        | Destination | Table Option                | Radio Button       | Use existing                                                                       |
        | Destination | Table (Schema)              | Dynamic Expression | @pipeline().parameters.sinkschema                                                  |
        | Destination | Table (Table name)          | Dynamic Expression | @pipeline().parameters.sinktable                                                   |
        | Destination | Advanced -> Pre-copy Script | Dynamic Expression | DELETE FROM @{pipeline().parameters.sinkschema}.@{pipeline().parameters.sinktable} |
    1. Add **Set variable** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                |
        | -------- | ------------- | ------------------ | -------------------- |
        | General  | Name          | String             | Set pipeline endtime |
        | Settings | Variable type | Radio Button       | Pipeline variable    |
        | Settings | Name          | Dropdown           | pipelineendtime      |
        | Settings | Value         | Dynamic Expression | @utcnow()            |
    1. Add **Script** activity, drag the green arrow from the previous activity to it and configure:
       | Tab      | Configuration   | Value Type   | Value                                             |
       | -------- | --------------- | ------------ | ------------------------------------------------- |
       | General  | Name            | String       | Update Pipeline Run details                       |
       | Settings | Data store type | Radio Button | External                                          |
       | Settings | Connection      | Dropdown     | Connection to FabricMetdataOrchestration Database |
       | Settings | Script(1)       | Radio Button | NonQuery                                          |
       | Settings | Script(2)       | Dynamic Expression  | Update dbo.PipelineOrchestrator_FabricWarehouse set batchloaddatetime = '@{pipeline().parameters.batchloaddatetime}', loadstatus = '@{activity('Copy data to warehouse').output.executionDetails[0].status}',  rowsinserted= @{activity('Copy data to warehouse').output.rowsCopied}, rowsupdated=0, pipelinestarttime='@{variables('pipelinestarttime')}', pipelineendtime = '@{variables('pipelineendtime')}' where sourceschema = '@{pipeline().parameters.sourceschema}' and sourcetable = '@{pipeline().parameters.sourcetable}'   |
    1. Exit the **True activities** box of the **If condition** by clicking on  **Main canvas** in the upper left corner
1. Now configure the **If False** activities. Your False activities will be a flow of activities when the table to be loaded should be an incremental load. When completed, the False activities will look like this: ![dw-incremental](images/dw-false.jpg)
    1. Add **Lookup** activity and configure:
        | Tab      | Configuration               | New parameter name | Paramater Type | Value Type         | Value                                                                             |
        | -------- | --------------------------- | ------------------ | -------------- | ------------------ | --------------------------------------------------------------------------------- |
        | General  | Name                        |                    |                | String             | Load Incremental via Stored Proc                                                  |
        | Settings | Data store type             |                    |                | Radio button       | Workspace                                                                         |
        | Settings | Workspace data store type   |                    |                | Drop down          | jhFTAFabricWarehouse                                                              |
        | Settings | Use query                   |                    |                | Radio button       | Stored procedure                                                                  |
        | Settings | Stored procedure name       |                    |                | Dynamic Expression | @{pipeline().parameters.storedprocschema}.@{pipeline().parameters.storedprocname} |
        | Settings | Stored procedure parameters | EndDate            | DateTime       | Dynamic Expression | @pipeline().parameters.sourceenddate                                              |
        | Settings |                             | StartDate          | DateTime       | Dynamic Expression | @pipeline().parameters.sourcestartdate                                            |
        | Settings | First row only              |                    |                | Check box          | Checked                                                                           |
    1. Add **Set variable** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration | Value Type         | Value                     |
        | -------- | ------------- | ------------------ | ------------------------- |
        | General  | Name          | String             | Set pipeline endtime_incr |
        | Settings | Variable type | Radio Button       | Pipeline variable         |
        | Settings | Name          | Dropdown           | pipelineendtime           |
        | Settings | Value         | Dynamic Expression | @utcnow()                 |
    1. Add **Script** activity, drag the green arrow from the previous activity to it and configure:
        | Tab      | Configuration   | Value Type   | Value                                             |
        | -------- | --------------- | ------------ | ------------------------------------------------- |
        | General  | Name            | String       | Update Pipeline Run details_incr                  |
        | Settings | Data store type | Radio Button | External                                          |
        | Settings | Connection      | Dropdown     | Connection to FabricMetdataOrchestration Database |
        | Settings | Script(1)       | Radio Button | NonQuery                                          |
        | Settings | Script(2)       | Dynamic Expression | Update dbo.PipelineOrchestrator_FabricWarehouse set batchloaddatetime = '@{pipeline().parameters.batchloaddatetime}', loadstatus = 'Succeeded', sinkmaxdatetime = '@{activity('Load Incremental via Stored Proc').output.firstRow.MaxDate}', sourcestartdate = '@{activity('Load Incremental via Stored Proc').output.firstRow.MaxDate}', rowsupdated = @{activity('Load Incremental via Stored Proc').output.firstRow.UpdateCount}, rowsinserted = @{activity('Load Incremental via Stored Proc').output.firstRow.InsertCount},  pipelinestarttime='@{variables('pipelinestarttime')}', pipelineendtime = '@{variables('pipelineendtime')}' where sourceschema = '@{pipeline().parameters.sourceschema}' and sourcetable = '@{pipeline().parameters.sourcetable}'  |
    1. Exit the **False activities** box of the **If condition** by clicking on  **Main canvas** in the upper left corner
### Configure the Orchestrator Pipeline Part 3 - Invoke Pipeline to load from Fabric Lakehouse to Fabric Data Warehouse
We are on the final steps! Update the Orchestrator pipeline, **orchestrator Load WWI to Fabric**, to load data from the first Fabric Lakehouse to the Data Warehouse. When you are done, your pipeline should look like this: ![orchestrator-done](images/wwi-pipeline-complete.jpg)
1. Add add another **Lookup** activity.  Get a 2nd green arrow from the **Wait** activity to it and configure:
    | Tab      | Configuration   | Value Type         | Value                                                                                                            |
    | -------- | --------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------- |
    | General  | Name            | String             | Get tables to load to warehouse                                                                                  |
    | Settings | Data store type | Radio button       | External                                                                                                         |
    | Settings | Connection      | Drop down          | Connection to your metadata database                                                                             |
    | Settings | Connection Type | Drop down          | Azure SQL Database                                                                                               |
    | Settings | Use query       | Radio button       | Query                                                                                                            |
    | Settings | Query           | Dynamic Expression | select \* from dbo.PipelineOrchestrator_FabricWarehouse where skipload=0 and @{pipeline().parameters.loaddwh} =1 |
    | Settings | First row only  | Check box          | Not Checked                                                                                                      |
1. Add **For each** activity, drag the green arrow from the previous activity to it and configure:
    | Tab        | Configuration | Value Type                                    | Value                                                     |
    | ---------- | ------------- | --------------------------------------------- | --------------------------------------------------------- |
    | General    | Name          | String                                        | For each table to load to warehouse                       |
    | Settings   | Items         | Dynamic Expression                            | @activity('Get tables to load to warehouse').output.value |
1. Click on the pencil in the **Activities** box of the **For each** and add an **Invoke Pipeline** activity and configure as follows:
    | Tab      | Configuration      | Parameter Name    | Value Type         | Value                           |
    | -------- | ------------------ | ----------------- | ------------------ | ------------------------------- |
    | General  | Name               |                   | String             | Invoke Load Warehouse Table     |
    | Settings | Invoked pipeline   |                   | Dropdown           | Load Warehouse Table            |
    | Settings | Wait on completion |                   | Checkbox           | Checked                         |
    | Settings | Parameters         | sourcestartdate   | Dynamic Expression | @item().sourcestartdate         |
    | Settings | Parameters         | sourceenddate     | Dynamic Expression | @item().sourceenddate           |
    | Settings | Parameters         | sourceschema      | Dynamic Expression | @item().sourceschema            |
    | Settings | Parameters         | sourcetable       | Dynamic Expression | @item().sourcetable             |
    | Settings | Parameters         | sinkschema        | Dynamic Expression | @item().sinkschema              |
    | Settings | Parameters         | loadtype          | Dynamic Expression | @item().loadtype                |
    | Settings | Parameters         | batchloaddatetime | Dynamic Expression | @variables('batchloaddatetime') |
    | Settings | Parameters         | sinktable         | Dynamic Expression | @item().sinktable               |
    | Settings | Parameters         | storedprocschema  | Dynamic Expression | @item().storedprocschema        |
    | Settings | Parameters         | storedprocname    | Dynamic Expression | @item().storedprocname          |
1. Exit the **Activities** box in the **For each** activity by clicking on  **Main canvas** in the upper left corner
You are done!! Save the **orchestrator Load WWI to Fabric** pipeline. Let's run it. But if you already ran the pipelines to load to the 2 Lakeshouses, just run the load from the first or "Bronze" Lakehouse to the Data Warehouse. ![part3-run](images/part3-run.jpg)