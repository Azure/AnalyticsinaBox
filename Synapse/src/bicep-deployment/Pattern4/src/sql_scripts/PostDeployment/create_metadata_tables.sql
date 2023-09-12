USE sampledb
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tablses_to_copy]') AND type in (N'U'))
DROP TABLE [dbo].[tablses_to_copy]
GO


CREATE TABLE [dbo].[tablses_to_copy] 
(
    ID INT PRIMARY KEY IDENTITY(1,1),
    SCHEMA_NAME VARCHAR(50),
    TABLE_NAME VARCHAR(50),
    FULLOAD INT, --1/0 1= yes, 0 =no
    WATER_MARK_COLUMN varchar(50),
    DATA_FETCHED_TILL_TIMESTAMP DATETIME,
    MERGE_JOIN_CONDITION Varchar(255)
)

GO

INSERT INTO [dbo].[tablses_to_copy] 
Select 'SalesLT','Address','1' ,'','2000-01-01 12:00:00', ''

GO

INSERT INTO [dbo].[tablses_to_copy] 
Select 'SalesLT','Customer','1', '','2000-01-01 12:00:00', ''

GO

INSERT INTO [dbo].[tablses_to_copy] 
Select 'SalesLT','CustomerAddress','1', '','2000-01-01 12:00:00', ''

GO

INSERT INTO [dbo].[tablses_to_copy] 
Select 'SalesLT','SalesOrderDetail', 0 , 'ModifiedDate', '2000-01-01 13:00:00', 'source.SalesOrderDetailID = target.SalesOrderDetailID'

GO

INSERT INTO [dbo].[tablses_to_copy] 
Select 'SalesLT','SalesOrderHeader', 0 , 'ModifiedDate', '2000-01-01 13:00:00', 'source.SalesOrderID = target.SalesOrderID'

GO

USE sampledb
GO

DROP PROC IF EXISTS dbo.usp_update_watermark_datetime
GO

CREATE PROC dbo.usp_update_watermark_datetime @schemaName varchar(50), @tableName varchar(50), @watermarkValueToBeUpdated DATETIME
AS
UPDATE dbo.tablses_to_copy
SET DATA_FETCHED_TILL_TIMESTAMP= @watermarkValueToBeUpdated
where SCHEMA_NAME=@schemaName and TABLE_NAME=@tableName

