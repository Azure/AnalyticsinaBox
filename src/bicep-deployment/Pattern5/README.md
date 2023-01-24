Instructions for Pattern 5 - Metadata Driven Pipeline for Azure SQL and ADLS Gen 2

1. Create a new Azure Resource Group
1. Create a new Synapse Analytics Workspace in the new Resource Group; Specify the option to create a new Azure Data Lake Storage Gen 2 (ADLS) storage account <https://learn.microsoft.com/en-us/azure/synapse-analytics/quickstart-create-workspace>
1. Download the World Wide Imports Database and install as an Azure SQL Database <https://learn.microsoft.com/en-us/sql/samples/wide-world-importers-oltp-install-configure?view=sql-server-ver16>
Connect to the the World Wide Importers Database in SQL Server Management Studio or in Azure Data Studio and run the scripts in the source_scripts folder
1. Create a new Azure SQL Database for your Metadata Driven Pipeline Control table https://learn.microsoft.com/en-us/azure/azure-sql/database/single-database-create-quickstart?view=azuresql&tabs=azure-portal
1. Connect to the database for your Metadata Driven Pipeline Control table and run the scripts in the orchestrator_scripts folder
1. Update the parameter file for the ARM template
1. Deploy the ARM template to your Synapse Analytics Workspace
1. Connect to the Serverless SQL endpoint in SSMS or Azure Data Studio and run the scripts in the synapse_serverless_scripts folder