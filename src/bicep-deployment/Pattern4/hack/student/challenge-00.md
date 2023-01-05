# Challenge 0: Pre-requisites - Ready, Set, GO!
**[Home](../readme.md)** - [Next Challenge >](./challenge-01.md)

## Introduction
Welcome to the hack! Let's get started with reviewing the prerequistes and setting up the environment.

## Description

### Azure Subscription
1. An Azure account with an active subscription. Note: If you don't have access to an Azure subscription, you may be able to start with a free account. 
1. Subscription and resources provisioned 
    1. Which corp subscription to use – existing or new?
        1. Potentially in dev/test subscription 
1. Alternatively, developers can create a Free trial account from here – they will need to provide credit card details for starting (it does not get charged). Rs 10,000/- one time credit valid for 30 days 
1. Devs should be able to continue to build/keep code 

### Azure Resources
1. Create a Resource Group in your preferred region (e.g. Central India) and make note of the name.
1. Ensure you have Contributor Access to the new Resource Group.  
1. Create the below resources, using default configurations unless otherwise specified, in the same Resource Group & same region.  
Note: Do not configure services to utilised Private Endpoints. Whilst this would be a valid deployment option in organisations, it will increase the complexity of the hack.
    1. Azure SQL Database
        * General Purpose, 2 vCore.
        * Provision with sample AdventureWorksLT database.
        * Allow SQL Auth and record admin account and password.
        * Locally Redundant Storage (LRS) backups.
        * Allow public endpoint access.
        * Allow access to Azure services.
    1. Synapse workspace  
        * Create anew ADLSv2 account during Synapse workspace creation.
        * Create a file system within the ADLSv2.
        * Disable Managed VNET, Enable Public access, Allow Connections from all IP addresses
    1. Spark Pool within Synapse (2x small nodes)
    1. Key Vault
        * Standard Tier 
        * Vault access policies 
        * Add access policy for “key and secret management template” for synapse workspace managed identity (name is same as synapse workspace name) and Azure AD User (Developer Identity) 

### Software needed on developer machines 
1. SQL Server Management Studio (SSMS) ***OR*** Azure Data studio 
1. PBI Desktop

## Success Criteria
1. Azure SQL Database, Synapse (with a Spark Pool) & Key vault are deployed to a new Resource Group, all within the same region
