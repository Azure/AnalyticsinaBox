-- This is auto-generated code

/*

Create the database curated_svrlss if you are running the script for the first time
*/

--create database curated_svrlss 
--go

USE curated_svrlss
GO

CREATE OR ALTER VIEW  dbo.saleslt_address
AS

SELECT
     *
FROM
    OPENROWSET(
        BULK 'https://opnhckadlstorage.dfs.core.windows.net/curated/SalesLT.Address/',
        FORMAT = 'DELTA'
    ) AS [result]

GO

CREATE OR ALTER VIEW  dbo.saleslt_Customer
AS

SELECT
     *
FROM
    OPENROWSET(
        BULK 'https://opnhckadlstorage.dfs.core.windows.net/curated/SalesLT.Customer/',
        FORMAT = 'DELTA'
    ) AS [result]

GO

CREATE OR ALTER VIEW  dbo.saleslt_SalesOrderDetail
AS

SELECT
     *
FROM
    OPENROWSET(
        BULK 'https://opnhckadlstorage.dfs.core.windows.net/curated/SalesLT.SalesOrderDetail/',
        FORMAT = 'DELTA'
    ) AS [result]

GO
CREATE OR ALTER VIEW  dbo.saleslt_SalesOrderHeader
AS

SELECT
     *
FROM
    OPENROWSET(
        BULK 'https://opnhckadlstorage.dfs.core.windows.net/curated/SalesLT.SalesOrderHeader/',
        FORMAT = 'DELTA'
    ) AS [result]

GO


