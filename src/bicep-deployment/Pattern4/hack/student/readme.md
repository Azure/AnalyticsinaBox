# Pattern 4 Hack

## Introduction

In this hack, you will look at the process of creating an end-to-end solution using Azure Synapse Analytics – Data Ingestion Pipelines, Spark based data engineering and SQL Serverless query. 

## Learning Objective

What you will learn in this hack 

1. How to build a Data Pipeline in Synapse
    1. Data Set - Tabular (csv/parquet)
        1. SQL Db sample dataset
            1. Metadata table – dynamic pipeline
            1. Stored Proc to update the watermark
        1. Synapse Pipeline
            1. Copy activity with metadata driven loop – dynamic pipeline (table sql db)
            1. Synapse notebook
        1. Incremental Load (with timestamp) - Merge
        1. Full Load (Without timestamp) – Merge
        1. Simple Data Lake structures (RAW (parquet/csv) and curated (Delta)
        1. Delta format
        1. Spark notebook based transformation and upserts(Merge)
        1. Serverless SQL – create external table / views
    1. PowerBI consumption in Desktop 
    1. Identity and security best practices for this solution 
    1. How to leverage Azure Key Vault
    1. How and why to leverage Managed Identities 
    1. Basic Source Control setup (But no CI/CD pipelines) 
    1. Demo walkthrough / discussion 

## Challenges

* [Challenge 0: Prerequistes and setup](challenge-00.md)
* [Challenge 1: Create a Data Lake](challenge-01.md)
* [Challenge 2: Extract data from SQL Source, to Data Lake](challenge-02.md)
* [Challenge 3: RAW zone to Curated (Delta Table)](challenge-03.md)
* [Challenge 4: Parameterized pipelines & incremental loads](challenge-04.md)
* [Challenge 5: Visualize Data in Power BI using Serverless SQL](challenge-05.md)
* [Challenge 6: (Optional) - Setup source control integration](challenge-06.md)