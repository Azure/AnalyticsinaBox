Instructions for Pattern 5 - Metadata Driven Pipeline for Azure SQL and ADLS Gen 2

1. Create a New Resource Group
1. Create a New Synapse Analytics Workspace in the New Resource Group; Specify the option to create a new Azure Data Lake Storage Gen 2 (ADLS) storage account <https://learn.microsoft.com/en-us/azure/synapse-analytics/quickstart-create-workspace>
1. Download the World Wide Imports Database and install as an Azure SQL Database <https://learn.microsoft.com/en-us/sql/samples/wide-world-importers-oltp-install-configure?view=sql-server-ver16>
1. Log into the World Wide Importers Database in SQL Server Management Studio or in Azure Data Studio and give your Synapse Analytics Workspace access to the World Wide Importers Database
    1. CREATE USER yoursysnapseanalyticcsworkspacename FROM  EXTERNAL PROVIDER  WITH DEFAULT_SCHEMA=[dbo]
    1. ALTER ROLE db_owner ADD MEMBER yoursysnapseanalyticcsworkspacename 
1. Create a new Azure SQL Database for your Metadata Driven Pipeline Control table https://learn.microsoft.com/en-us/azure/azure-sql/database/single-database-create-quickstart?view=azuresql&tabs=azure-portal
Run the SQL Script to create a new database and the metadata driven pipeline control table
Gyour Synapse Analytics Workspace access to the World Wide Importers Database
    1. CREATE USER yoursysnapseanalyticcsworkspacename FROM  EXTERNAL PROVIDER  WITH DEFAULT_SCHEMA=[dbo]
    1. ALTER ROLE db_owner ADD MEMBER yoursysnapseanalyticcsworkspacename
1. Update the parameter file for the ARM template
1. Deploy the ARM template to your Synapse Analytics Workspace
1. Create a new Synapse Serverless Database and schemas called Bronze and Silver
1. 1. In Synapse Studio, go to the Develop hub
1. 1. Create a new SQL script.
1. 1. CREATE DATABASE yoursynapseserverlesssdatabasename
1. 1. CREATE SCHEMA BRONZE
1. 1. CREATE SCHEMA SILVER
1.
