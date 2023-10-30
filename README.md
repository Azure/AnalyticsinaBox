## <img src="Assets/images/ftaanalyticsinabox.png" alt="FTA Analytics-in-a-Box: Deployment Accelerator" style="float: left; margin-right:10px;" />
&nbsp;

Getting up and running with Synapse, Fabric or Azure Databricks can be a complex undertaking with some organizations and engineers getting blocked on their first scenario. Having an easy to understand and intuitive template that they can rely on that will demonstrate what the overall life cycle can look like, how the ingestion pipelines should be set up, and how the data goes from raw to curated in their Delta Lake.  

This project aims to provide an "Easy Button" for common scenarios. Something that shows how the pieces fit together in easy to deploy templates. Using the **patterns** available here, engineers will be able to quickly setup a Synapse or Fabric or Databricks environment which optionally includes streaming & batch ingestion, Data Lake with zones, Delta tables as well as meta-driven pipelines.

| Key Contacts | GitHub ID | Email |
|--------------|------|-----------|
| Samarendra Panda | @Sam-Panda | sapa@microsoft.com | 
| Neeraj Jhaveri | @neerajjhaveri | neeraj.jhaveri@microsoft.com | 
| Andrés Padilla | @AndresPad | andres.padilla@microsoft.com | 
| Ben Harding | @BennyHarding | ben.harding@microsoft.com
| Jean Hayes | @jehayesms | jean.hayes@microsoft.com |
| Thiago Rotta | @rottathiago | thiago.rotta@microsoft.com |

##
## Available Patterns
This repository contains several scenarios, or, 'patterns' for you to deploy into your own environment. Below is a summary:

## Synapse
* **Pattern 1**: Azure Synapse Analytics workspace with a Data Lake and Serverless & Dedicated SQL Pools.
* **Pattern 2**: Azure Synapse Analytics workspace with a Data Lake, Serverless & Dedicated SQL Pools and Spark Pools.
* **Pattern 3**: Streaming solution with an Azure Function (Event Generator), Event Hubs, Synapse with Spark Pool and Streaming Notebook and a Data Lake (ADLSv2). Deployed via Azure DevOps.
* **Pattern 4**: Batch loading example from a source SQL database through to a Data Lake using Synapse Spark.
* **Pattern 5**: Metadata Driven Synapse Pipelines with Azure SQL DB Source, Data Lake/Parquet Sink and Synapse Serverless Star Schema

## Databricks

## Fabric
* **Pattern 1**:  End-to-End Metadata Driven Pipeline in Fabric, From SQL Source to Lakehouse to Gold Lakehouse
* **Pattern 2**:  End-to-End Metadata Driven Pipeline in Fabric, From SQL Source to Lakehouse to Data Warehouse